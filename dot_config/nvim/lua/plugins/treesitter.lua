local TS = require("nvim-treesitter")

local ensure_installed = {
  "bash",
  "c",
  "cpp",
  "cmake",
  "css",
  "diff",
  "fish",
  "gitignore",
  "html",
  "http",
  "javascript",
  "jsdoc",
  "json",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "scss",
  "regex",
  "toml",
  "svelte",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

TS.install(ensure_installed)

-- MDX has no parser of its own; render it with the Markdown one.
vim.filetype.add({
  extension = {
    mdx = "mdx",
  },
})
vim.treesitter.language.register("markdown", "mdx")

local treesitter_group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = treesitter_group,
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang or not vim.treesitter.language.add(lang) then
      return
    end

    if not vim.treesitter.highlighter.active[ev.buf] then
      vim.treesitter.start(ev.buf, lang)
    end

    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- Keep parsers in sync when the plugin itself is installed or updated.
local hooks = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
    vim.cmd("TSUpdate")
  end
end
vim.api.nvim_create_autocmd("PackChanged", { callback = hooks })
