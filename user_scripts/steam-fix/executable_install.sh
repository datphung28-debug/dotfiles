#!/usr/bin/env bash
# Fix Steam bị chặn ở VN (Viettel): DNS bị đầu độc + DPI chặn theo SNI.
# Cách xử lý: DNS sạch + tách gói TLS ClientHello (không VPN, không mất băng thông).
# Dùng: sudo bash install.sh
set -euo pipefail

[ "${EUID}" -eq 0 ] || { echo "Chạy lại bằng: sudo bash $0"; exit 1; }

# Remove the unit name used by older versions so it cannot keep running after
# an upgrade and reintroduce the old rules on the next boot.
systemctl disable --now zapret-steam 2>/dev/null || true
rm -f /etc/systemd/system/zapret-steam.service
systemctl daemon-reload

# Cloudflare WARP can leave its full-tunnel routes behind while the tunnel is
# down. Those linkdown routes are more specific than the normal DHCP default
# route and blackhole Internet traffic after reboot.
nmcli connection down id CloudflareWARP 2>/dev/null || true
ip route flush dev CloudflareWARP 2>/dev/null || true
ip -6 route flush dev CloudflareWARP 2>/dev/null || true

ZAPRET=/opt/zapret
DIR=/etc/zapret
HOSTLIST=$DIR/blocked-sites.txt
EXCLUDELIST=$DIR/hostlist-exclude.txt
CONF=$DIR/nfqws-blocked-sites.conf
NFT=$DIR/blocked-sites.nft
UNIT=/etc/systemd/system/zapret-blocked-sites.service
QUEUE=200

say() { printf '\n==> %s\n' "$*"; }

say "1/5 Cài thư viện build (libnetfilter_queue)"
pacman -S --needed --noconfirm libnetfilter_queue libnfnetlink libmnl >/dev/null

say "2/5 Build nfqws từ zapret"
if [ ! -x "$ZAPRET/binaries/my/nfqws" ]; then
  [ -d "$ZAPRET/.git" ] || git clone --depth 1 -q https://github.com/bol-van/zapret.git "$ZAPRET"
  make -C "$ZAPRET" -j"$(nproc)" >/dev/null
fi
install -Dm755 "$ZAPRET/binaries/my/nfqws" /usr/local/bin/nfqws

say "3/5 Ghi cấu hình"
install -d -m755 "$DIR"
cat > "$HOSTLIST" <<'EOF'
steampowered.com
steamcommunity.com
reddit.com
redd.it
redditmedia.com
redditstatic.com
EOF

# Do not inspect/desync TikTok traffic. Its video and CDN connections are
# long-lived and sensitive to any modification of the initial TLS packets.
cat > "$EXCLUDELIST" <<'EOF'
tiktok.com
tiktokv.com
tiktokcdn.com
ibytedtos.com
muscdn.com
byteimg.com
byteoversea.com
EOF

# Chỉ đưa 6 gói đầu của mỗi kết nối vào queue -> phần còn lại đi thẳng, không giảm tốc độ.
cat > "$NFT" <<EOF
table inet zapret {
    chain out {
        type filter hook output priority mangle; policy accept;
        tcp dport { 80, 443 } ct original packets 1-6 queue num $QUEUE bypass
    }
}
EOF

cat > "$UNIT" <<EOF
[Unit]
Description=DPI bypass cho Steam va Reddit (tach goi TLS ClientHello)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=-/usr/bin/nft delete table inet zapret
ExecStartPre=-/usr/bin/ip route flush dev CloudflareWARP
ExecStartPre=-/usr/bin/ip -6 route flush dev CloudflareWARP
ExecStartPre=/usr/bin/nft -f $NFT
ExecStart=/usr/local/bin/nfqws @$CONF
ExecStopPost=-/usr/bin/nft delete table inet zapret
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable zapret-blocked-sites >/dev/null 2>&1 || true

say "4/5 Đổi DNS sang Cloudflare/Google (DNS nhà mạng trả 127.0.0.1 cho tên miền Steam)"
conns=$(nmcli -t -f NAME,TYPE connection show --active \
  | awk -F: '$1!="CloudflareWARP" && $2!="loopback" && $2!="bridge" && $2!="vpn" {print $1}')
[ -n "$conns" ] || { echo "Không thấy kết nối NetworkManager nào đang hoạt động."; exit 1; }
while IFS= read -r c; do
  # Use IPv4 DNS only. A fixed IPv6 resolver is unreachable on many
  # connections and can make DNS appear dead after a reboot.
  nmcli connection modify "$c" ipv4.dns "1.1.1.1 8.8.8.8" ipv4.ignore-auto-dns yes
  nmcli connection modify "$c" ipv6.dns "" ipv6.ignore-auto-dns yes
  nmcli connection up "$c" >/dev/null
  echo "   DNS -> 1.1.1.1 / 8.8.8.8 cho: $c"
done <<< "$conns"

resolvectl flush-caches 2>/dev/null || true
ip=$(getent hosts store.steampowered.com | awk '{print $1}' | head -1)
echo "   store.steampowered.com -> ${ip:-<không phân giải được>}"
case "$ip" in
  ""|127.*|::1) echo "DNS vẫn bị chặn, dừng lại. Kiểm tra lại nmcli/resolved."; exit 1;;
esac

say "5/5 Bật dịch vụ và tự dò chiến lược phù hợp"
write_conf() { printf -- '--qnum=%s\n--hostlist=%s\n--hostlist-exclude=%s\n--dpi-desync=%s\n--dpi-desync-split-pos=%s\n' \
  "$QUEUE" "$HOSTLIST" "$EXCLUDELIST" "$1" "$2" > "$CONF"; }

check() {
  local ok=0 c
  for _ in 1 2; do
    c=$(curl -s -o /dev/null -m 8 -w '%{http_code}' https://store.steampowered.com/ || true)
    [ "$c" = "200" ] && ok=$((ok+1))
  done
  [ "$ok" -ge 2 ]
}

for strat in "multisplit:1" "multisplit:2" "multidisorder:1" "multisplit:3"; do
  write_conf "${strat%%:*}" "${strat##*:}"
  systemctl restart zapret-blocked-sites || true
  sleep 1.5
  if check; then
    echo "   OK: chiến lược ${strat} hoạt động."
    echo
    echo "Xong. Mở lại Steam."
    echo "Gỡ cài đặt: sudo bash $(dirname "$0")/uninstall.sh"
    exit 0
  fi
  echo "   thử ${strat}: chưa qua"
done

systemctl stop zapret-blocked-sites
echo
echo "Không chiến lược nào qua được. Dò tự động bằng:"
echo "  sudo $ZAPRET/blockcheck.sh"
echo "Hoặc gỡ: sudo bash $(dirname "$0")/uninstall.sh"
exit 1
