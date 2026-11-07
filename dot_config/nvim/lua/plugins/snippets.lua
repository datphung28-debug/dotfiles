-- LuaSnip setup + snippet loading.
--
-- Snippet sources:
--   * friendly-snippets (VSCode format) -> installed via vim.pack
--   * your own snippets (Lua format)    -> lua/snippets/<filetype>.lua
local ls = require("luasnip")

ls.setup({
  history = true,
  -- re-evaluate insert/function nodes while typing
  updateevents = "TextChanged,TextChangedI",
  -- keep snippet session alive while moving around in insert mode,
  -- leave it when the cursor leaves the snippet region
  region_check_events = "CursorMoved,InsertEnter,InsertLeave",
  delete_check_events = "TextChanged,InsertLeave",
  enable_autosnippets = true,
})

-- VSCode-format collections (friendly-snippets ships a `snippets/` dir
-- that is picked up automatically from the runtimepath).
-- Loading these parses every snippet file, so wait until the first insert.
vim.api.nvim_create_autocmd("InsertEnter", {
  once = true,
  callback = function()
    require("luasnip.loaders.from_vscode").lazy_load()

    -- Your own Lua snippets: lua/snippets/<filetype>.lua (see the README there).
    require("luasnip.loaders.from_lua").lazy_load({
      paths = { vim.fn.stdpath("config") .. "/lua/snippets" },
    })
  end,
})
