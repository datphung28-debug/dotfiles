-- HTML/CSS helpers: class completions, documentation and stylesheet peek.
require("html-css").setup({
  enable_on = { "html", "javascriptreact", "typescriptreact" },
  documentation = {
    auto_show = true,
  },
  peek = {
    enabled = true,
    border = "rounded",
    position = "center",
    width = 0.5,
    height = 0.5,
    focus = true,
    style = "minimal",
  },
  style_sheets = {
    "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/bulma/1.0.3/css/bulma.min.css",
  },
})
