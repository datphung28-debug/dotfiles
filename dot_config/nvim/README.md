# Neovim config

Cấu hình Neovim dùng plugin manager built-in (`vim.pack`, Neovim ≥ 0.12).

## Cấu trúc

```
init.lua                  # leader + require core/pack/plugins
nvim-pack-lock.json       # lockfile của vim.pack (commit file này)
.stylua.toml              # format Lua
after/lsp/<server>.lua    # override LSP config (merge sau nvim-lspconfig)

lua/
├── core/                 # Neovim thuần, không require plugin
│   ├── init.lua
│   ├── options.lua
│   ├── keymaps.lua       # chỉ keymap builtin
│   ├── autocmds.lua
│   └── workarounds.lua
├── pack.lua              # khai báo plugin (vim.pack.add)
├── plugins/              # mỗi file = 1 nhóm: setup + keymap cùng chỗ
│   ├── init.lua          # thứ tự load (dependency order)
│   ├── treesitter.lua
│   ├── colorscheme.lua
│   ├── snippets.lua
│   ├── completion.lua    # blink.cmp + cssclass
│   ├── lsp.lua           # mason + vim.lsp + keymap LSP
│   ├── ai.lua            # NeoCodeium
│   ├── ui.lua            # mini.icons, diagnostics
│   ├── statusline.lua    # lualine, incline, bufferline
│   ├── snacks.lua        # picker/explorer/dashboard/terminal + keymap
│   ├── git.lua           # gitsigns, gitlinker
│   ├── diff.lua          # mini.diff, codediff
│   ├── session.lua       # persistence: lưu/khôi phục phiên làm việc
│   ├── editing.lua       # pairs, comments, colors, autotag, flash
│   ├── markdown.lua      # render-markdown
│   ├── formatting.lua    # conform
│   └── web.lua           # html-css
├── utils/                # helper dùng chung, không side-effect
│   ├── icons.lua
│   ├── lualine.lua
│   ├── lazygit.lua
│   ├── map.lua
│   └── root.lua          # root dự án: LSP workspace -> marker -> cwd
├── cssclass/             # local blink source (CSS class/id completion)
└── snippets/             # snippet cá nhân <filetype>.lua
```

## Quy ước

- File plugin nào thì keymap của plugin đó nằm trong file đó; `core/keymaps.lua` chỉ có map builtin.
- `lua/pack.lua` chỉ khai báo plugin, không setup.
- `lua/plugins/init.lua` là nơi duy nhất quyết định thứ tự load.
- Không dùng global (`_G.*`).
- Giữ `after/lsp/` để override config của `nvim-lspconfig`.
- Giữ `lua/snippets/` vì LuaSnip load theo module path.

## Toàn bộ keymap

`<leader>` = `Space`. Cột Mode: trống = normal, `x` = visual, `o` = operator-pending,
`i` = insert, `t` = terminal, `c` = command-line. Keymap của LSP là **buffer-local**
(chỉ tồn tại trong buffer tương ứng) và sẽ thắng keymap global cùng phím.

### Di chuyển & chỉnh sửa

| Phím | Mode | Chức năng |
| --- | --- | --- |
| `j` / `k` | n, x | Xuống/lên dòng (dùng `gj`/`gk` khi không có count) |
| `<Down>` / `<Up>` | n, x | Như `j` / `k` |
| `J` / `K` | n, x | Nhảy 5 dòng xuống/lên |
| `<A-j>` / `<A-k>` | n, i, x | Di chuyển dòng lên/xuống (visual giữ selection) |
| `+` / `-` | n | Tăng/giảm số dưới cursor (`<C-a>` / `<C-x>`) |
| `x` | n | Xoá ký tự, không ghi vào register |
| `<` / `>` | x | Thụt lề trái/phải, giữ selection |
| `gco` / `gcO` | n | Thêm comment ở dòng dưới/trên |
| `<leader>o` / `<leader>O` | n | Mở dòng mới dưới/trên, không auto-continue comment |
| `<C-s>` | n, i, x, s | Lưu file |
| `<Esc>` | n | Xoá highlight tìm kiếm |
| `n` / `N` | n, x, o | Match kế/trước, giữ hướng tìm và center |
| `*` / `#` | n | Tìm từ dưới cursor (center) |
| `,` / `.` / `;` | i | Thêm undo break-point khi gõ |
| `<leader>h` | n | Select All |
| `<leader>ur` | n | Redraw + clear highlight + diffupdate |

### Cửa sổ & tab

| Phím | Mode | Chức năng |
| --- | --- | --- |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | n, t | Chuyển window trái/xuống/lên/phải |
| `<C-Up>` / `<C-Down>` | n | Tăng/giảm chiều cao window |
| `<C-Left>` / `<C-Right>` | n | Giảm/tăng chiều rộng window |
| `<leader>-` / `<leader>\|` | n | Split ngang / dọc |
| `<leader>nt` | n | Tab mới |
| `<Tab>` / `<S-Tab>` | n | Tab kế/trước |

### Buffer

| Phím | Mode | Chức năng |
| --- | --- | --- |
| `<S-h>` / `<S-l>` | n | Buffer trước/kế (BufferLine, có wrap) |
| `[b` / `]b` | n | Buffer trước/kế (`:bprevious` / `:bnext`, không wrap) |
| `\` | n | Danh sách buffer (picker, nhảy tới window đang mở) |
| `<leader>bd` / `<leader>bo` / `<leader>bi` | n | Xoá buffer hiện tại / buffer khác / buffer không hiển thị |
| `<leader>bl` / `<leader>br` | n | Xoá buffer bên trái / bên phải |

### Tìm kiếm & picker (`;` prefix)

| Phím | Mode | Chức năng |
| --- | --- | --- |
| `;f` / `;r` | n | Tìm file / live grep theo root dự án |
| `;;` | n | Mở lại picker gần nhất |
| `;e` / `;c` / `;n` | n | Diagnostics / LSP incoming calls / notifications |
| `;g` / `;h` | n | Lazygit / git diff (hunks) |
| `]]` / `[[` | n, t | Reference kế/trước (Snacks words) |

### LSP (buffer-local)

| Phím | Mode | Chức năng |
| --- | --- | --- |
| `gd` / `gD` / `gy` | n | Definition / Declaration / Type definition (picker) |
| `gr` | n | References (picker) |
| `gI` | n | Source definition (vtsls) / implementation |
| `gK` | n | Signature help |
| `<C-k>` | i | Signature help (blink khi menu mở, LSP khi không) |
| `<leader>ch` | n | Hover |
| `<leader>ca` | n, x | Code action |
| `<leader>cc` / `<leader>cC` | n | Run codelens / refresh codelens |
| `<leader>co` / `<leader>cA` | n, x | Organize imports / source action |
| `<leader>rn` | n | Rename symbol (IncRename, preview trực tiếp) |
| `<leader>cR` | n | Rename file |
| `<leader>cl` | n | LSP info |
| `<leader>cs` / `<leader>cS` | n | Symbols / references-definitions (Trouble) |

### Git & diff

| Phím | Mode | Chức năng |
| --- | --- | --- |
| `<leader>gb` / `<leader>gB` | n | Blame dòng / cả buffer |
| `<leader>go` | n | Mở file ở commit đang blame |
| `<leader>gs` / `<leader>gh` | n | Stage/unstage buffer / hunk (gitsigns) |
| `gh` / `gH` | n, x | Apply / reset hunk (mini.diff) |
| `gh` | o | Textobject chọn hunk |
| `]c` / `[c` | n, x, o | Hunk kế/trước |
| `]H` / `[H` | n, x, o | Hunk cuối/đầu |
| `<leader>gd` | n | Toggle mini.diff overlay |
| `<leader>dv` | n | Toggle CodeDiff (side-by-side) |
| `<leader>dh` / `<leader>dH` | n | Lịch sử file hiện tại / repo (CodeDiff) |

### Diagnostics & quickfix

| Phím | Mode | Chức năng |
| --- | --- | --- |
| `]d` / `[d` | n | Diagnostic kế/trước |
| `]e` / `[e` | n | Error kế/trước |
| `]w` / `[w` | n | Warning kế/trước |
| `]q` / `[q` | n | Quickfix kế/trước |
| `<leader>xx` / `<leader>xX` | n | Diagnostics toàn bộ / buffer hiện tại (Trouble) |
| `<leader>xQ` / `<leader>xL` | n | Quickfix / location list (Trouble) |

### Flash

| Phím | Mode | Chức năng |
| --- | --- | --- |
| `s` / `S` | n, x, o | Flash jump / Flash Treesitter |
| `f` / `F` / `t` / `T` | n, x, o | Char motion có nhãn (thay builtin) |
| `;` / `,` | n, x, o | Lặp lại `f`/`t` |
| `r` | o | Remote flash |
| `R` | x, o | Treesitter search |
| `<C-s>` | c | Toggle flash search trong command-line |

### Phiên làm việc & giao diện

| Phím | Mode | Chức năng |
| --- | --- | --- |
| `<leader>qs` / `<leader>qS` | n | Khôi phục phiên dự án / chọn phiên |
| `<leader>ql` / `<leader>qd` | n | Phiên gần nhất / không lưu phiên hiện tại |
| `<leader>t` | n | Đổi theme (lưu cho lần mở sau) |
| `<leader>fm` | n, x | Format code |
| `<leader>mr` | n | Bật/tắt render-markdown cho buffer hiện tại |
| `<leader>e` | n | File explorer (Snacks picker) |

`:ToggleFormatter` bật/tắt auto format on save cho mọi buffer (mặc định tắt).

### Terminal

| Phím | Mode | Chức năng |
| --- | --- | --- |
| `<leader>ft` / `<C-/>` / `<C-_>` | n, t | Toggle terminal nổi ở root dự án |
| `<Esc><Esc>` | t | Thoát terminal mode |

### Dashboard (khi mở Neovim không có file)

| Phím | Chức năng |
| --- | --- |
| `f` / `n` / `g` | Find File / New File / Find Text |
| `s` / `q` | Restore Session / Quit |

### Insert & command-line (AI + completion)

| Phím | Mode | Chức năng |
| --- | --- | --- |
| `<C-l>` | i | NeoCodeium: nhận toàn bộ gợi ý |
| `<M-l>` / `<M-u>` | i | NeoCodeium: nhận 1 từ / 1 dòng |
| `<M-]>` / `<M-[>` | i | NeoCodeium: gợi ý kế/trước |
| `<C-]>` | i | NeoCodeium: bỏ gợi ý |
| `<C-Space>` / `<C-e>` | i | blink: mở / đóng menu |
| `<CR>` | i | blink: nhận item (fallback xuống dòng) |
| `<Tab>` / `<S-Tab>` | i | blink: nhảy snippet tới/lùi |
| `<C-k>` | i | blink: hiện/ẩn signature |
| `<Up>` / `<Down>`, `<C-n>` / `<C-p>` | i | blink: chọn item |
| `<C-b>` / `<C-f>` | i | blink: cuộn documentation |
| `<BS>` / `<CR>` | i, c | mini.pairs: đóng/mở cặp ngoặc, xuống dòng |

Command-line completion của blink đã tắt; command-line dùng wildmenu mặc định (`<Tab>`).

### Snacks explorer

`<leader>e` mở explorer dạng picker. Dùng keymap picker mặc định; `<CR>` mở file, `<Esc>` đóng.

### Builtin đã bị thay đổi

- `J` / `K`: mất `J` (join) và `K` (keywordprg) — đổi thành nhảy 5 dòng.
- `s` / `S`: mất substitute; dùng `c`/`cc` hoặc Flash.
- `f` `F` `t` `T` `;` `,`: Flash char motion (tự fallback motion gốc khi không có nhãn).
- `x`: không ghi vào register.
- `+` / `-`: tăng/giảm số (mất motion `+` / `-`).
- `gh` / `gH`: mini.diff (mất Select mode của Neovim).
- `<Tab>` / `<S-Tab>`: chuyển tab (mất jumplist `<C-i>`; `<C-o>` vẫn lùi jumplist).
- `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>`: chuyển window (đè `<C-j>` xuống dòng).
- `dw`: giữ builtin; muốn xoá lùi một từ thì dùng `db` hoặc `"_db`.
- `<C-s>`: lưu file ở insert/visual/normal/select; trong command-line là flash search.
- LuaSnip chỉ dùng `<Plug>luasnip-*` (blink preset `luasnip` gọi tới), không cần map tay.

## Theme và phiên làm việc

- Theme chọn bằng `<leader>t` được ghi vào `stdpath("state")/colorscheme` và tự áp dụng lại khi mở Neovim.
- Phiên làm việc do `persistence.nvim` lưu tự động khi thoát (`<leader>qs` để khôi phục, hoặc phím `s` ở dashboard). Session nằm trong `stdpath("state")/sessions/`, tách riêng theo git branch.

## Tối ưu khởi động

- `vim.loader.enable()` cache bytecode Lua (nhanh hơn ~25-30%).
- LuaSnip loaders và NeoCodeium setup chờ `InsertEnter`; codediff setup chạy sau màn hình đầu.
- `updatetime=200` (hover/gitsigns/diagnostics phản hồi sớm hơn), `timeoutlen=300`.
- `<leader>t` nạp Themery khi dùng lần đầu.

## AI completion

NeoCodeium cần token một lần: chạy `:NeoCodeium auth` rồi dán API key.

## Kiểm tra

```sh
nvim --headless "+qa"            # không lỗi khi khởi động
nvim +"checkhealth"
```
