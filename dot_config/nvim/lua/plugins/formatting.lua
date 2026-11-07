-- Formatting (conform.nvim). Auto format on save starts off; :ToggleFormatter enables it.
vim.g.autoformat = false
local oxfmtFormatter = { "oxfmt", "prettierd", "prettier", stop_after_first = true }

require("conform").setup({
  -- Saving a file with no formatter should not warn, especially with autoformat on.
  notify_no_formatters = false,
  default_format_opts = {
    timeout_ms = 3000,
    async = false,
    quiet = false,
    lsp_format = "fallback",
  },
  formatters_by_ft = {
    javascript = oxfmtFormatter,
    typescript = oxfmtFormatter,
    javascriptreact = oxfmtFormatter,
    typescriptreact = oxfmtFormatter,
    json = oxfmtFormatter,
    css = oxfmtFormatter,
    html = oxfmtFormatter,
    markdown = oxfmtFormatter,
    yaml = oxfmtFormatter,
    scss = oxfmtFormatter,
    ["markdown.mdx"] = oxfmtFormatter,
    lua = { "stylua" },
    fish = { "fish_indent" },
    c = { "clang-format" },
  },
  formatters = {
    oxfmt = {
      require_cwd = true,
    },
  },
  format_on_save = function()
    return vim.g.autoformat and {} or nil
  end,
})

vim.api.nvim_create_user_command("ToggleFormatter", function()
  vim.g.autoformat = not vim.g.autoformat
  vim.notify("Autoformat on save: " .. (vim.g.autoformat and "on" or "off"))
end, { desc = "Toggle autoformat on save (global)" })

vim.keymap.set({ "n", "x" }, "<leader>fm", function()
  require("conform").format()
end, { desc = "Format code" })
