# dotfiles

Cấu hình cá nhân cho CachyOS/Arch, quản lý bằng [chezmoi](https://www.chezmoi.io/).

## Cài trên máy mới

```bash
chezmoi init --apply git@github.com:datphung28-debug/dotfiles.git
```

Lệnh này apply dotfiles và chạy `run_onchange_install-packages.sh` để cài toàn bộ gói (trừ `dusky` và `rain-clock`).

## Được quản lý

- **Shell**: fish (`config.fish`, `conf.d/tide.fish`, 3 function tùy chỉnh: key bindings, fzf) + `.bashrc`, `.zshrc`, `.profile`
- **Editor**: nvim (kèm `.stylua.toml`)
- **Terminal**: kitty, tmux (chỉ file cấu hình, không gồm plugins)
- **Desktop**: hyprland (config Lua), matugen (templates + generated), rofi, uwsm, waybar
- **Theme**: qt5ct, qt6ct, Kvantum, gtk-3.0, gtk-4.0, `.gtkrc-2.0`
- **CLI/GUI**: yazi, lazygit, stylua
- Symlink được giữ nguyên (`kitty`, `yazi`, `Kvantum` → `matugen/generated`)

## Không quản lý

- `fish_variables*`: chứa token/secret và file backup
- `tmux/plugins`: git clone, cài lại bằng tpm (`prefix + I`)
- `dusky`, `rain-clock`: script riêng
- cache, dữ liệu ứng dụng

## Lệnh thường dùng

```bash
chezmoi add <file>       # thêm file vào repo
chezmoi re-add           # cập nhật các file đã quản lý
chezmoi diff             # xem khác biệt máy vs repo
chezmoi apply            # áp dụng repo lên máy
chezmoi update           # pull + apply
chezmoi cd               # vào source dir
```

Sau khi sửa config, đẩy lên remote:

```bash
chezmoi cd && git add -A && git commit -m "update" && git push
```

## Ghi chú

- Một số file còn đường dẫn tuyệt đối `/home/admin`; khôi phục với username khác cần sửa hoặc chuyển sang template.
- Script gói dùng `--needed` nên không nâng cấp gói đã cài; muốn cập nhật hệ thống dùng `paru -Syu`.
- Danh sách gói là snapshot của máy hiện tại (kernel, NVIDIA, hardware-specific), phù hợp máy CachyOS tương tự.
