-- Completion menu (blink.cmp) + project CSS class/id completion (lua/cssclass).
local icons = require("utils.icons")

-- CSS class/id completion from project markup files (local plugin: lua/cssclass)
require("cssclass").setup()
local function inside_empty_pair()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before, after = line:sub(col, col), line:sub(col + 1, col + 1)
  return (before == "(" and after == ")") or (before == "[" and after == "]") or (before == "{" and after == "}")
end

---@module 'blink.cmp'
---@type blink.cmp.Config
require("blink.cmp").setup({
  snippets = {
    -- use LuaSnip as the snippet engine, not blink's built-in one
    preset = "luasnip",
  },
  completion = {
    accept = { auto_brackets = { enabled = true } },
    list = {
      selection = {
        preselect = true,
        auto_insert = false,
      },
    },
    menu = {
      border = "single",
      scrollbar = false,
      auto_show = function()
        return not inside_empty_pair()
      end,
      draw = {
        treesitter = { "lsp" },
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
      update_delay_ms = 50,
      treesitter_highlighting = true,
      window = {
        border = "rounded",
        scrollbar = false,
        winhighlight = "Normal:BlinkCmpDoc,FloatBorder:FloatBorder,EndOfBuffer:BlinkCmpDoc",
      },
    },
    ghost_text = {
      enabled = false,
    },
    trigger = {
      show_on_insert = false,
      show_on_insert_on_trigger_character = false,
      show_on_accept_on_trigger_character = false,
      show_on_backspace = false,
      show_on_backspace_in_keyword = false,
      show_on_backspace_after_accept = false,
      show_on_backspace_after_insert_enter = false,

      show_on_keyword = true,
      show_on_trigger_character = true,

      -- Several LSPs treat brackets as trigger characters. Block both halves
      -- too: mini.pairs feeds `(` and `)` for a single keypress, so either one
      -- could otherwise open the menu as soon as a pair is inserted.
      show_on_blocked_trigger_characters = { " ", "\n", "\t", "(", ")", "[", "]", "{", "}" },
    },
  },

  sources = {
    default = { "lsp", "path", "snippets", "buffer", "cssclass" },
    providers = {
      cssclass = {
        name = "CSS Class",
        module = "cssclass.source",
        score_offset = 10,
        max_items = 400,
      },
    },
  },

  cmdline = { enabled = false },
  keymap = {
    preset = "enter",
    ["<C-y>"] = { "select_and_accept" },
  },

  appearance = {
    kind_icons = icons.kinds,
  },
})
