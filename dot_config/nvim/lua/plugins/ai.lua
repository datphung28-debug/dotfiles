-- AI completion: NeoCodeium (Windsurf / Codeium).
-- Runs alongside blink.cmp: the completion menu and the AI ghost text are
-- independent, so both can be visible at the same time.
local neocodeium = require("neocodeium")

-- Starting the AI client costs a few ms and may check auth; do it on the first
-- insert instead of while the editor is starting up.
vim.api.nvim_create_autocmd("InsertEnter", {
  once = true,
  callback = function()
    neocodeium.setup({
      -- Never send secrets from .env files to the server.
      filter = function(bufnr)
        if vim.endswith(vim.api.nvim_buf_get_name(bufnr), ".env") then
          return false
        end
        return true
      end,
    })
  end,
})

local map = require("utils.map")

map({
  {
    "<C-l>",
    function()
      neocodeium.accept()
    end,
    desc = "AI: accept suggestion",
    mode = "i",
  },
  {
    "<M-l>",
    function()
      neocodeium.accept_word()
    end,
    desc = "AI: accept word",
    mode = "i",
  },
  {
    "<M-u>",
    function()
      neocodeium.accept_line()
    end,
    desc = "AI: accept line",
    mode = "i",
  },
  {
    "<M-]>",
    function()
      neocodeium.cycle_or_complete()
    end,
    desc = "AI: next suggestion",
    mode = "i",
  },
  {
    "<M-[>",
    function()
      neocodeium.cycle_or_complete(-1)
    end,
    desc = "AI: previous suggestion",
    mode = "i",
  },
  {
    "<C-]>",
    function()
      neocodeium.clear()
    end,
    desc = "AI: dismiss suggestion",
    mode = "i",
  },
})
