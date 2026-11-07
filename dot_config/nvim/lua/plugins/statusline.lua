-- Statusline (lualine), floating window labels (incline), buffer tabline.
local icons = require("utils.icons")
local lualine_utils = require("utils.lualine")

-- Take the theme lualine would pick automatically ("auto") and make the middle
-- section transparent. The left side keeps its colored blocks (mode/branch) and
-- the right side keeps its original blocks: light progress and a mode-colored
-- location block, so it still changes color with the current mode.
-- Lualine calls this function again on every ColorScheme change, so switching
-- themes with <leader>t keeps working.
local function transparent_theme()
  package.loaded["lualine.themes.auto"] = nil
  local ok, theme = pcall(require, "lualine.themes.auto")
  if not ok or type(theme) ~= "table" then
    return "auto"
  end

  local normal = type(theme.normal) == "table" and theme.normal or nil
  if not normal or type(normal.c) ~= "table" then
    return theme
  end

  -- Snapshot the original color before clearing any background.
  local c = vim.deepcopy(normal.c) -- middle: light text on a dark panel

  for _, mode in pairs(theme) do
    if type(mode) == "table" then
      -- Diagnostics/diff: no dark block, just text (x otherwise falls back to
      -- `c`, which is transparent).
      mode.x = { fg = c.fg, bg = "NONE" }

      -- y and z are intentionally left alone so lualine keeps its original
      -- fallbacks: y -> b (light progress block), z -> a (mode-colored
      -- location block). That is what makes the right side look like before
      -- and keeps the color changing with the current mode.

      -- Middle: the long file path area blends with the editor.
      if type(mode.c) == "table" then
        mode.c.bg = "NONE"
      end
    end
  end
  return theme
end

require("lualine").setup({
  options = {
    theme = transparent_theme,
    globalstatus = true,
    disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
    refresh = {
      events = {
        "WinEnter",
        "BufEnter",
        "BufWritePost",
        "SessionLoadPost",
        "FileChangedShellPost",
        "VimResized",
        "Filetype",
        "CursorMoved",
        "CursorMovedI",
        "ModeChanged",
        -- Macro
        "RecordingEnter",
        "RecordingLeave",
      },
    },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch" },
    lualine_c = {
      lualine_utils.root_dir(),
      { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
      {
        lualine_utils.pretty_path({
          length = 0,
          relative = "cwd",
          modified_hl = "MatchParen",
          directory_hl = "",
          filename_hl = "Bold",
          modified_sign = "",
          readonly_icon = " 󰌾 ",
        }),
      },
    },
    lualine_x = {
      lualine_utils.macro_recording(),
      {
        "diagnostics",
        symbols = {
          error = icons.diagnostics.Error,
          warn = icons.diagnostics.Warn,
          info = icons.diagnostics.Info,
          hint = icons.diagnostics.Hint,
        },
      },
      {
        "diff",
        symbols = {
          added = icons.git.added,
          modified = icons.git.modified,
          removed = icons.git.removed,
        },
        source = function()
          local gitsigns = vim.b.gitsigns_status_dict
          if gitsigns then
            return {
              added = gitsigns.added,
              modified = gitsigns.changed,
              removed = gitsigns.removed,
            }
          end
        end,
      },
    },
    lualine_y = {
      { "progress", separator = " ", padding = { left = 1, right = 1 } },
    },
    lualine_z = {
      { "location", padding = { left = 1, right = 1 } },
    },
  },
})

-- Sections with an explicit background keep it, but components that only set a
-- foreground (filename uses `Bold`, the root dir sets just a fg, ...) inherit
-- the StatusLine background. Clear that base so the middle section blends with
-- the transparent editor, while the colored side blocks stay unchanged.
local function transparent_statusline()
  for _, name in ipairs({ "StatusLine", "StatusLineNC" }) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    hl.bg = nil
    vim.api.nvim_set_hl(0, name, hl)
  end
end

transparent_statusline()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("UserTransparentStatusline", { clear = true }),
  callback = function()
    vim.schedule(transparent_statusline)
  end,
})

require("incline").setup({
  highlight = {
    groups = {
      InclineNormal = {
        guibg = "NONE",
        guifg = "#A4DD00",
      },
      InclineNormalNC = {
        guifg = "NONE",
        guibg = "NONE",
      },
    },
  },

  window = {
    margin = {
      vertical = 0,
      horizontal = 1,
    },
  },

  hide = {
    cursorline = true,
  },

  render = function(props)
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")

    if vim.bo[props.buf].modified then
      filename = "[+] " .. filename
    end

    local icon, color = require("nvim-web-devicons").get_icon_color(filename)

    return {
      { icon or "", guifg = color },
      { " " },
      { filename },
    }
  end,
})

require("bufferline").setup({
  options = {
    always_show_bufferline = false,
    diagnostics = "nvim_lsp",
    -- Delete the buffer (not just the window) and keep the layout tidy.
    close_command = function(n)
      require("snacks").bufdelete(n)
    end,
    right_mouse_command = function(n)
      require("snacks").bufdelete(n)
    end,
  },
})

local map = require("utils.map")

map({
  { "<Leader>br", "<cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
  { "<Leader>bl", "<cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
  { "<S-h>", "<cmd>BufferLineCyclePrev<CR>", desc = "Prev Buffer" },
  { "<S-l>", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer" },
  { "[b", "<cmd>bprevious<cr>", desc = "Prev Buffer" },
  { "]b", "<cmd>bnext<cr>", desc = "Next Buffer" },
  {
    "<leader>bd",
    function()
      require("snacks").bufdelete()
    end,
    desc = "Delete Buffer",
  },
  {
    "<leader>bo",
    function()
      require("snacks").bufdelete.other()
    end,
    desc = "Delete Other Buffers",
  },
  {
    "<leader>bi",
    function()
      require("snacks").bufdelete.invisible()
    end,
    desc = "Delete Invisible Buffers",
  },
})
