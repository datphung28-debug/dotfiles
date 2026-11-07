-- Small editing helpers: brackets, comments, colors, tag closing, jumps.
local map = require("utils.map")

require("mini.pairs").setup({
  modes = { insert = true, command = true, terminal = false },
  skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
  skip_ts = { "string" },
  skip_unbalanced = true,
  markdown = true,
})

require("todo-comments").setup({
  highlight = {
    pattern = [[.*[[:alnum:]_]@<!\zs(KEYWORDS)\s*:]],
  },
})
require("ts-comments").setup()

-- Colors
vim.lsp.document_color.enable(false)
require("nvim-highlight-colors").setup({
  render = "background",
  enable_hex = true,
  enable_short_hex = true,
  enable_rgb = true,
  enable_hsl = true,
  enable_hsl_without_function = true,
  enable_ansi = true,
  enable_var_usage = true,
  enable_tailwind = false,
})

require("nvim-ts-autotag").setup({
  opts = {
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = false,
  },
})

require("flash").setup()

map({
  {
    "s",
    function()
      require("flash").jump()
    end,
    mode = { "n", "x", "o" },
    desc = "Flash",
  },
  {
    "S",
    function()
      require("flash").treesitter()
    end,
    mode = { "n", "x", "o" },
    desc = "Flash Treesitter",
  },
  {
    "r",
    function()
      require("flash").remote()
    end,
    mode = "o",
    desc = "Remote Flash",
  },
  {
    "R",
    function()
      require("flash").treesitter_search()
    end,
    mode = { "o", "x" },
    desc = "Treesitter Search",
  },
  {
    "<c-s>",
    function()
      require("flash").toggle()
    end,
    mode = "c",
    desc = "Toggle Flash Search",
  },
})
