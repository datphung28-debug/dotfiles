-- Git integration: hunk signs/actions (gitsigns) + link picker (gitlinker).
local map = require("utils.map")

require("gitsigns").setup()
require("gitlinker").setup()

map({
  {
    "<leader>gb",
    function()
      require("gitsigns").blame_line()
    end,
    desc = "Blame current line",
  },
  {
    "<leader>gB",
    function()
      require("gitsigns").blame()
    end,
    desc = "Blame buffer",
  },
  {
    "<leader>go",
    function()
      local async = require("gitsigns.async")
      local cache = require("gitsigns.cache").cache

      async.run(function()
        local bufnr = vim.api.nvim_get_current_buf()
        local lnum = vim.api.nvim_win_get_cursor(0)[1]
        local bcache = cache[bufnr]
        if not bcache then
          return
        end

        bcache:get_blame(lnum)
        local blame = bcache.blame
        if not blame or not blame.entries or not blame.entries[lnum] then
          return
        end

        local info = blame.entries[lnum]
        local sha = info.commit.sha

        -- Check if uncommitted (sha is all zeros)
        if tonumber("0x" .. sha:sub(1, 8)) == 0 then
          vim.notify("Line not committed yet", vim.log.levels.WARN)
          return
        end

        vim.cmd.tabnew()
        require("gitsigns.actions.diffthis").show(bufnr, sha, info.filename)
        async.schedule()
        pcall(vim.api.nvim_win_set_cursor, 0, { info.orig_lnum or lnum, 0 })
      end)
    end,
    desc = "Open file from blamed commit",
  },
  {
    "<leader>gs",
    function()
      local gs = require("gitsigns")
      if #(gs.get_hunks() or {}) > 0 then
        gs.stage_buffer()
      else
        gs.reset_buffer_index()
      end
    end,
    desc = "Toggle stage buffer",
  },
  {
    "<leader>gh",
    function()
      require("gitsigns").stage_hunk()
    end,
    desc = "Toggle stage hunk",
  },
})
