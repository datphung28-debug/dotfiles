-- Markdown rendering: headings, code blocks, tables, lists, ...
-- LaTeX is off: no latex parser or utftex/latex2text on this machine.
require("render-markdown").setup({
  latex = { enabled = false },
})

vim.keymap.set("n", "<leader>mr", function()
  require("render-markdown").buf_toggle()
end, { desc = "Toggle markdown render" })
