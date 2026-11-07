-- Plugin declarations for vim.pack (see :h vim.pack).
-- Their configuration lives in lua/plugins/*.lua.
local gh = function(x)
  return "https://github.com/" .. x
end

vim.pack.add({
  -- UI
  { src = gh("craftzdog/solarized-osaka.nvim") },
  { src = gh("rebelot/kanagawa.nvim") },
  { src = gh("catppuccin/nvim") },
  { src = gh("folke/tokyonight.nvim") },
  { src = gh("ellisonleao/gruvbox.nvim") },
  { src = gh("sainnhe/gruvbox-material") },
  { src = gh("zaldih/themery.nvim") },
  { src = gh("nvim-mini/mini.icons") },
  { src = gh("folke/snacks.nvim") },
  { src = gh("folke/trouble.nvim") },
  { src = gh("nvim-lualine/lualine.nvim") },
  { src = gh("b0o/incline.nvim") },
  { src = gh("esmuellert/codediff.nvim") },
  { src = gh("akinsho/bufferline.nvim") },
  { src = gh("nvim-tree/nvim-web-devicons") },

  -- Editor
  { src = gh("stevearc/conform.nvim") },
  { src = gh("nvim-treesitter/nvim-treesitter") },
  { src = gh("nvim-mini/mini.pairs") },
  { src = gh("craftzdog/mini.diff"), version = "feat/grouping" },
  { src = gh("saghen/blink.cmp"), version = vim.version.range("^1") },
  { src = gh("folke/todo-comments.nvim") },
  { src = gh("lewis6991/gitsigns.nvim") },
  { src = gh("linrongbin16/gitlinker.nvim") },
  { src = gh("brenoprata10/nvim-highlight-colors") },
  { src = gh("windwp/nvim-ts-autotag") },
  { src = gh("folke/ts-comments.nvim") },
  { src = gh("MeanderingProgrammer/render-markdown.nvim") },
  { src = gh("rafamadriz/friendly-snippets") },
  { src = gh("L3MON4D3/LuaSnip") },
  { src = gh("smjonas/inc-rename.nvim") },
  { src = gh("folke/flash.nvim") },
  { src = gh("jezda1337/nvim-html-css") },

  -- LSP
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("mason-org/mason.nvim") },
  { src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") },

  -- Util
  { src = gh("folke/persistence.nvim") },

  -- AI completion
  { src = gh("monkoose/neocodeium") },
})
