-- Session management (persistence.nvim).
-- One session per project (and branch), saved automatically on exit.
require("persistence").setup({
  dir = vim.fn.stdpath("state") .. "/sessions/",
  -- Git branch is part of the session name, so each branch keeps its own layout.
  branch = true,
  -- Minimum number of file buffers needed before a session is saved.
  need = 1,
})

local map = require("utils.map")

map({
  {
    "<leader>qs",
    function()
      require("persistence").load()
    end,
    desc = "Restore Session",
  },
  {
    "<leader>qS",
    function()
      require("persistence").select()
    end,
    desc = "Select Session",
  },
  {
    "<leader>ql",
    function()
      require("persistence").load({ last = true })
    end,
    desc = "Restore Last Session",
  },
  {
    "<leader>qd",
    function()
      require("persistence").stop()
    end,
    desc = "Don't Save Current Session",
  },
})
