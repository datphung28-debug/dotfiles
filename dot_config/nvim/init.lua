-- Cache compiled Lua modules (same trick lazy.nvim/LazyVim uses) for a faster startup.
vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("core") -- builtin options/keymaps/autocmds (no plugins)
require("pack") -- plugin declarations (vim.pack)
require("plugins") -- plugin setup, one module per feature
