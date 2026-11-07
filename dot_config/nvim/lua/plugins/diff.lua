-- Diff views: inline hunks (mini.diff) + side-by-side (codediff).
local map = require("utils.map")

require("mini.diff").setup({
  view = {
    overlay_style = "hunk",
  },
  mappings = {
    goto_next = "]c",
    goto_prev = "[c",
  },
})

-- codediff pulls in a lot of modules; set it up after the first screen so it
-- does not delay startup. The `:CodeDiff` commands come from the plugin itself.
vim.schedule(function()
  require("codediff").setup({
    explorer = {
      width = 50,
      auto_open_on_cursor = true,
      view_mode = "tree",
      line_stats = {
        enabled = true,
      },
    },
    diff = {
      compact = true,
      compact_context_lines = 8,
      compact_sync_folds = true,
    },
    keymaps = {
      view = {},
    },
  })
end)

map({
  {
    "<leader>gd",
    function()
      require("mini.diff").toggle_overlay()
    end,
    desc = "Toggle MiniDiff overlay",
  },
  { "<leader>dv", "<cmd>CodeDiff<cr>", desc = "Toggle CodeDiff" },
  -- File history
  { "<leader>dh", "<cmd>CodeDiff history %<cr>", desc = "File history (current file)" },
  { "<leader>dH", "<cmd>CodeDiff history<cr>", desc = "File history (repo)" },
})
