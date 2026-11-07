-- Snacks: picker, dashboard, notifications, terminal, lazygit, ...
local Snacks = require("snacks")
local root = require("utils.root")

Snacks.setup({
  words = { enabled = true },
  bigfile = { enabled = true },
  -- Animated scrolling is disabled: it feels laggy in large files.
  scroll = { enabled = false },
  dashboard = {
    enabled = true,
    preset = {
      header = [[
▓█████▄  ▄▄▄     ▄▄▄█████▓▓█████▄ ▓█████ ██▒   █▓
▒██▀ ██▌▒████▄   ▓  ██▒ ▓▒▒██▀ ██▌▓█   ▀▓██░   █▒
░██   █▌▒██  ▀█▄ ▒ ▓██░ ▒░░██   █▌▒███   ▓██  █▒░
░▓█▄   ▌░██▄▄▄▄██░ ▓██▓ ░ ░▓█▄   ▌▒▓█  ▄  ▒██ █░░
░▒████▓  ▓█   ▓██▒ ▒██▒ ░ ░▒████▓ ░▒████▒  ▒▀█░  
 ▒▒▓  ▒  ▒▒   ▓▒█░ ▒ ░░    ▒▒▓  ▒ ░░ ▒░ ░  ░ ▐░  
 ░ ▒  ▒   ▒   ▒▒ ░   ░     ░ ▒  ▒  ░ ░  ░  ░ ░░  
 ░ ░  ░   ░   ▒    ░       ░ ░  ░    ░       ░░  
   ░          ░  ░           ░       ░  ░     ░  
 ░                         ░                 ░   
      ]],
      keys = {
        { icon = "\u{f002} ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
        {
          icon = "\u{f15b} ",
          key = "n",
          desc = "New File",
          action = function()
            vim.ui.input({ prompt = "New file: " }, function(name)
              if not name or name == "" then
                return
              end
              local path = vim.fn.fnamemodify(vim.fn.expand(name), ":p")
              vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
              vim.cmd.edit(vim.fn.fnameescape(path))
            end)
          end,
        },
        { icon = "\u{f022} ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        {
          icon = "\u{f1da} ",
          key = "s",
          desc = "Restore Session",
          action = ":lua require('persistence').load()",
        },
        { icon = "\u{f426} ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
    },
  },
  explorer = { enabled = true },
  image = {
    enabled = true,
    formats = vim.split("png jpg jpeg gif bmp webp tiff heic avif mp4 mov avi mkv webm pdf", " "),
    doc = { enabled = true, inline = false, float = false, max_width = 80, max_height = 40 },
  },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true, timeout = 3000 },
  picker = {
    enabled = true,
    sources = {
      files = { hidden = true, ignored = true },
      explorer = { hidden = true, ignored = true },
    },
  },
  quickfile = { enabled = true },
  scope = { enabled = true },
})

local map = require("utils.map")

-- Directory of the file in the current buffer (falls back to the process cwd
-- for unnamed buffers). Pickers scope to this instead of the project root, so
-- you only see files under the directory you are currently working in.
local function current_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" and not name:match("^%a[%w+.-]*://") then
    return vim.fs.dirname(name)
  end
  return vim.uv.cwd() or vim.fn.getcwd()
end

map({
  { "<leader>cl", Snacks.picker.lsp_config, desc = "Lsp Info" },
  { "<leader>cR", Snacks.rename.rename_file, desc = "Rename File" },
  {
    ";f",
    function()
      Snacks.picker.files({ cwd = current_dir() })
    end,
    desc = "Find files (current dir)",
  },
  {
    ";r",
    function()
      Snacks.picker.grep({ cwd = root.get() })
    end,
    desc = "Live grep (root dir)",
  },
  { ";;", Snacks.picker.resume, desc = "Resume picker" },
  {
    "<leader>e",
    function()
      Snacks.explorer()
    end,
    desc = "File Explorer",
  },
  {
    "\\\\",
    function()
      Snacks.picker.buffers({
        confirm = function(picker, item)
          picker:close()
          if not item then
            return
          end
          -- If the buffer is already shown in a window (any tab),
          -- jump to that window instead of opening it here.
          vim.schedule(function()
            for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
              for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
                if vim.api.nvim_win_get_buf(win) == item.buf then
                  vim.api.nvim_set_current_tabpage(tab)
                  vim.api.nvim_set_current_win(win)
                  return
                end
              end
            end
            vim.api.nvim_set_current_buf(item.buf)
          end)
        end,
      })
    end,
    desc = "List buffers",
  },
  {
    "<leader>ft",
    function()
      Snacks.terminal(nil, { cwd = root.get() })
    end,
    desc = "Terminal (root dir)",
  },
  {
    "<C-/>",
    function()
      Snacks.terminal(nil, { cwd = root.get() })
    end,
    desc = "Terminal (root dir)",
    mode = { "n", "t" },
  },
  {
    "<C-_>",
    function()
      Snacks.terminal(nil, { cwd = root.get() })
    end,
    desc = "which_key_ignore",
    mode = { "n", "t" },
  },
  { ";e", Snacks.picker.diagnostics, desc = "Diagnostics" },
  { ";c", Snacks.picker.lsp_incoming_calls, desc = "LSP incoming calls" },
  { ";n", Snacks.picker.notifications, desc = "Notifications" },
  {
    ";g",
    function()
      require("utils.lazygit").open()
    end,
    desc = "Lazygit",
  },
  {
    ";h",
    Snacks.picker.git_diff,
    desc = "Git Diff (Hunks)",
  },
  {
    "]]",
    function()
      Snacks.words.jump(vim.v.count1)
    end,
    desc = "Next Reference",
    mode = { "n", "t" },
  },
  {
    "[[",
    function()
      Snacks.words.jump(-vim.v.count1)
    end,
    desc = "Prev Reference",
    mode = { "n", "t" },
  },
})
