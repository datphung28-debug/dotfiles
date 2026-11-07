-- cssclass.source
--
-- blink.cmp source: suggests class/id names (collected from the project's
-- markup files) while editing CSS selectors, and also inside `class="..."`
-- / `id="..."` attributes of markup buffers.
local source = {}

--- Characters allowed after a `.` / `#` in a CSS selector.
--- (no `:` so that `.btn:hover` is not treated as a class name)
local SELECTOR_TOKEN = "[%w_%-%.!/%%%[%]@#]"
--- Characters allowed inside a class name in general (includes `:` for
--- Tailwind variants used with `@apply` and in markup attributes).
local ANY_TOKEN = "[%w_%-%.:!/%%%[%]@#]"

--- @param opts table
function source.new(opts)
  opts = opts or {}
  local self = setmetatable({}, { __index = source })
  self.opts = opts
  return self
end

function source:enabled()
  local config = require("cssclass").config
  local ft = vim.bo.filetype
  return config.filetypes_set[ft] == true or config.markup_filetypes_set[ft] == true
end

function source:get_trigger_characters()
  return { ".", "#" }
end

--- Detect a CSS selector context: `.foo`, `#bar`, `@apply foo`.
--- @param before string text of the current line up to the cursor
--- @return string|nil kind, string partial, integer start_col (0-indexed byte col after the sigil)
local function selector_context(before)
  -- ignore /* comments */
  local open_comment = before:find("/%*")
  if open_comment then
    local close_comment = before:find("%*/")
    if not close_comment or close_comment < open_comment then
      return nil
    end
  end

  -- Tailwind: @apply rounded-lg ... (no sigil)
  local apply_partial = before:match("@apply%s+(" .. ANY_TOKEN .. "*)$")
  if apply_partial then
    return "class", apply_partial, #before - #apply_partial
  end

  -- Find the right-most `.` or `#` that starts a selector token.
  for pos = #before, 1, -1 do
    local char = before:sub(pos, pos)
    if char == "." or char == "#" then
      local prev = pos > 1 and before:sub(pos - 1, pos - 1) or ""
      -- `.` / `#` may start a selector (start of line, after whitespace or a
      -- combinator) or be part of a compound selector (`.btn.active`).
      -- A digit before the dot means it is a decimal number (`p-1.5`).
      local valid_prev = prev == "" or prev:match("[%s>+~,;(){}&|]") ~= nil or prev:match("[%a_%-%]%)]") ~= nil

      if valid_prev then
        local partial = before:sub(pos + 1)
        if partial:match("^" .. SELECTOR_TOKEN .. "*$") then
          -- Do not complete when we're in a declaration value
          -- (e.g. `color: .` or `background: url(x).`).
          local head = before:sub(1, pos - 1)
          local segment = head:match("[^;{}]*$") or head
          if not segment:match("^%s*[%w%-]+%s*:%s") then
            return char == "." and "class" or "id", partial, pos
          end
        end
      end
    end
  end
end

--- Detect a class/id attribute value context: class="fo|", id='ap|',
--- className={`fo|`}, :class="fo |", class="btn pri|" ...
--- @param before string
--- @return string|nil kind, string partial, integer start_col
local function attribute_context(before)
  local quote_pos, quote, attr

  -- find the opening quote of the attribute value we are inside of
  for pos, char in before:gmatch("()([\"'`])") do
    local head = before:sub(1, pos - 1)
    local name = head:match("([%w_:%-%.%[%]]+)%s*=%s*{[%s]*$") or head:match("([%w_:%-%.%[%]]+)%s*=%s*$")
    -- the quote must still be open (no matching quote before the cursor)
    if name and not before:find(char, pos + 1, true) then
      quote_pos, quote, attr = pos, char, name
      break
    end
  end
  if not quote_pos then
    return nil
  end

  local key = require("cssclass.scanner")._attr_key(attr)
  if key ~= "class" and key ~= "id" then
    return nil
  end

  local typed = before:sub(quote_pos + 1)
  -- dynamic values (Vue/JSX/Svelte) cannot be completed safely
  if typed:find("[\"'`{}]", 1) or typed:match("^%s*[%[{]") then
    return nil
  end
  if quote == "`" and typed:find("%$", 1) then
    return nil
  end

  local partial = typed:match("(" .. ANY_TOKEN .. "*)$") or ""
  return key, partial, #before - #partial
end

--- @param ctx blink.cmp.Context
--- @return string|nil kind, string partial, integer start_col
local function detect_context(ctx)
  local config = require("cssclass").config
  local ft = vim.bo[ctx.bufnr].filetype
  local before = ctx.line:sub(1, ctx.cursor[2])

  if config.filetypes_set[ft] then
    return selector_context(before)
  end
  if config.markup_filetypes_set[ft] then
    return attribute_context(before)
  end
end

local function empty_response()
  return { items = {}, is_incomplete_forward = false, is_incomplete_backward = false }
end

--- @param ctx blink.cmp.Context
--- @param callback fun(response: blink.cmp.CompletionResponse)
function source:get_completions(ctx, callback)
  local kind, _, start_col = detect_context(ctx)
  if not kind then
    return callback(empty_response())
  end

  local cssclass = require("cssclass")
  local entries = cssclass.get_entries(ctx.bufnr)
  local list = kind == "class" and entries.classes or entries.ids
  if #list == 0 then
    return callback(empty_response())
  end

  local Kind = require("blink.cmp.types").CompletionItemKind
  local item_kind = kind == "class" and Kind.Class or Kind.EnumMember
  local row = ctx.cursor[1] - 1
  local end_col = ctx.cursor[2]

  local items = {}
  for index, entry in ipairs(list) do
    items[index] = {
      label = entry.name,
      filterText = entry.name,
      kind = item_kind,
      detail = ("%s · %d×"):format(kind, entry.count),
      -- keep more frequently used names in front when fuzzy scores tie
      sortText = ("%05d"):format(index),
      textEdit = {
        newText = entry.name,
        range = {
          start = { line = row, character = start_col },
          ["end"] = { line = row, character = end_col },
        },
      },
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      data = {
        cssclass = {
          name = entry.name,
          kind = kind,
          count = entry.count,
          files = entry.files,
        },
      },
    }
  end

  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
end

--- Lazily build the documentation window content.
--- @param item blink.cmp.CompletionItem
--- @param callback fun(item: blink.cmp.CompletionItem)
function source:resolve(item, callback)
  local data = item.data and item.data.cssclass
  if not data then
    return callback(item)
  end

  local files = data.files or {}
  local lines = {
    ("**%s** `%s` — used %d×"):format(data.kind, data.name, data.count),
    "",
    "Used in:",
  }
  for i = 1, math.min(#files, 8) do
    lines[#lines + 1] = "- `" .. vim.fn.fnamemodify(files[i], ":.") .. "`"
  end
  if #files > 8 then
    lines[#lines + 1] = ("- …and %d more file(s)"):format(#files - 8)
  end

  local resolved = vim.deepcopy(item)
  resolved.documentation = { kind = "markdown", value = table.concat(lines, "\n") }
  callback(resolved)
end

return source
