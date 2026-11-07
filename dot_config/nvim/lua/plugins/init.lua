-- Load order is a dependency order, not alphabetical:
--   snippets   -> blink.cmp uses LuaSnip as snippet engine
--   completion -> lsp below needs blink.cmp's LSP capabilities
require("plugins.treesitter")
require("plugins.colorscheme")
require("plugins.snippets")
require("plugins.completion")
require("plugins.lsp")
require("plugins.ai")
require("plugins.ui")
require("plugins.statusline")
require("plugins.snacks")
require("plugins.git")
require("plugins.diff")
require("plugins.session")
require("plugins.editing")
require("plugins.markdown")
require("plugins.formatting")
require("plugins.web")
