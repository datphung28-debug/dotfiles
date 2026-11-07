-- Colorschemes + live theme switcher. The selected theme is remembered across restarts.
local default_theme = "solarized-osaka"
local state_file = vim.fn.stdpath("state") .. "/colorscheme"

require("solarized-osaka").setup({
  style = "vivid",
  transparent = true,
  styles = {
    comments = { italic = true },
    keywords = { bold = true },
    sidebars = "transparent",
    floats = "transparent",
  },
  sidebars = {
    "qf",
    "vista_kind",
    "terminal",
    "spectre_panel",
    "staruptime",
    "Outline",
  },
})

require("kanagawa").setup({
  compile = false,
  undercurl = true,
  commentStyle = { italic = true },
  functionStyle = {},
  keywordStyle = { italic = true },
  statementStyle = { bold = true },
  typeStyle = {},
  transparent = true,
  dimInactive = false,
  terminalColors = true,
  theme = "wave",
  colors = {
    theme = {
      all = {
        ui = {
          bg_gutter = "none",
        },
      },
    },
  },

  overrides = function(colors)
    return {
      NormalFloat = { bg = "none" },
      FloatBorder = { bg = "none" },
      FloatTitle = { bg = "none" },

      NormalNC = { bg = "none" },
      SignColumn = { bg = "none" },
      EndOfBuffer = { bg = "none" },
    }
  end,
})

require("tokyonight").setup({
  style = "night",
  transparent = true,
  styles = {
    sidebars = "transparent",
    floats = "transparent",
  },
})

require("catppuccin").setup({
  flavour = "macchiato",
  background = {
    light = "latte",
    dark = "mocha",
  },
  transparent_background = true,
  float = {
    transparent = true,
    solid = true,
  },
  term_colors = true,
  dim_inactive = {
    enabled = false,
    shade = "dark",
    percentage = 0.15,
  },
  no_italic = false,
  no_bold = false,
  no_underline = false,
  styles = {
    comments = { "italic" },
    conditionals = { "italic" },
    loops = {},
    functions = {},
    keywords = {},
    strings = {},
    variables = {},
    numbers = {},
    booleans = {},
    properties = {},
    types = {},
    operators = {},
  },
  lsp_styles = {
    virtual_text = {
      errors = { "italic" },
      hints = { "italic" },
      warnings = { "italic" },
      information = { "italic" },
      ok = { "italic" },
    },
    underlines = {
      errors = { "underline" },
      hints = { "underline" },
      warnings = { "underline" },
      information = { "underline" },
      ok = { "underline" },
    },
    inlay_hints = {
      background = true,
    },
  },
  color_overrides = {},
  custom_highlights = {},
  auto_integrations = true,
  integrations = {
    cmp = true,
    gitsigns = true,
    nvimtree = true,
    notify = false,
    mini = {
      enabled = true,
      indentscope_color = "",
    },
  },
})

require("gruvbox").setup({
  terminal_colors = true,
  undercurl = true,
  underline = true,
  bold = false,
  italic = {
    strings = true,
    emphasis = true,
    comments = true,
    operators = false,
    folds = true,
  },
  strikethrough = true,
  invert_selection = false,
  invert_signs = false,
  invert_tabline = false,
  inverse = true,
  palette_overrides = {},
  transparent_mode = true,
})

---@param name string
---@return boolean
local function apply(name)
  return pcall(vim.cmd.colorscheme, name)
end

-- Restore the last theme picked with <leader>t, or fall back to the default.
local saved = vim.fn.filereadable(state_file) == 1 and vim.trim(vim.fn.readfile(state_file)[1] or "") or ""
if saved == "" or not apply(saved) then
  if not apply(default_theme) then
    vim.notify("Could not load theme: " .. default_theme, vim.log.levels.WARN)
  end
end

-- Persist every theme change (Themery previews included; the last one wins).
-- `last` starts at the startup theme so restoring it does not rewrite the file.
local last = vim.g.colors_name
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("UserColorscheme", { clear = true }),
  callback = function()
    local name = vim.g.colors_name
    if not name or name == "" or name == last then
      return
    end
    last = name
    vim.fn.mkdir(vim.fn.fnamemodify(state_file, ":h"), "p")
    vim.fn.writefile({ name }, state_file)
  end,
})

-- themery is only needed when switching themes; load it on first use.
vim.keymap.set("n", "<leader>t", function()
  require("themery").setup({
    themes = { "solarized-osaka", "gruvbox", "catppuccin", "tokyonight", "kanagawa" },
    livePreview = true,
  })
  vim.cmd.Themery()
end, { desc = "Theme switcher" })
