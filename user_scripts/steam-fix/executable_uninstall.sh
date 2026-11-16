#!/usr/bin/env bash
# Gỡ fix Steam: tắt dịch vụ, xoá nft rule, trả DNS về DHCP.
set -euo pipefail

[ "${EUID}" -eq 0 ] || exec sudo bash "$0" "$@"

systemctl disable --now zapret-blocked-sites 2>/dev/null || true
systemctl disable --now zapret-steam 2>/dev/null || true
rm -f /etc/systemd/system/zapret-blocked-sites.service \
  /etc/systemd/system/zapret-steam.service /usr/local/bin/nfqws
systemctl daemon-reload
nft delete table inet zapret 2>/dev/null || true
rm -rf /etc/zapret

# WARP may leave its full-tunnel routes behind when its interface is already
# down. Bring the profile down before restoring the normal connections.
nmcli connection down id CloudflareWARP 2>/dev/null || true
ip route flush dev CloudflareWARP 2>/dev/null || true
ip -6 route flush dev CloudflareWARP 2>/dev/null || true

# Keep VPN profiles out of the DHCP DNS restoration. In particular, changing
# the WARP profile here does not remove its routes and can make the stale
# profile come back on the next NetworkManager reload.
active_conns=$(nmcli -t -f NAME,TYPE connection show --active \
  | awk -F: '$1!="CloudflareWARP" && $2!="loopback" && $2!="bridge" && $2!="vpn" {print $1}')
conns=$(nmcli -t -f NAME,TYPE connection show \
  | awk -F: '$1!="CloudflareWARP" && $2!="loopback" && $2!="bridge" && $2!="vpn" {print $1}')
while IFS= read -r c; do
  [ -n "$c" ] || continue
  nmcli connection modify "$c" ipv4.ignore-auto-dns no ipv4.dns "" 2>/dev/null || true
  nmcli connection modify "$c" ipv6.ignore-auto-dns no ipv6.dns "" 2>/dev/null || true
done <<< "$conns"

while IFS= read -r c; do
  [ -n "$c" ] || continue
  nmcli connection up "$c" >/dev/null 2>&1 || true
done <<< "$active_conns"

echo "Đã gỡ và khôi phục DNS DHCP; các kết nối đang dùng đã được bật lại."
