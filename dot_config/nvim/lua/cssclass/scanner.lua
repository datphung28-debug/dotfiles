-- cssclass.scanner
--
-- Walks a project directory and collects every class/id used in markup files
-- (HTML, Vue, Svelte, JSX/TSX, PHP, ...). The result is then used by the
-- blink.cmp source in `cssclass.source`.
--
-- The parser deliberately avoids Lua patterns in the hot loop: it searches for
-- "=" (plain `find`), walks back over the attribute name and then reads the
-- quoted value. This keeps a full project scan in the low milliseconds.
local M = {}

local uv = vim.uv or vim.loop

local B = string.byte
local SUB = string.sub

local QUOTE_CHARS = { [34] = '"', [39] = "'", [96] = "`" }

local function is_space(byte)
  return byte == 32 or byte == 9 or byte == 13
end

local function is_separator(byte)
  return byte == nil or byte == 32 or byte == 9 or byte == 10 or byte == 13 or byte == 44
end

--- Bytes allowed in an attribute name (letters, digits, `_ - : . [ ] @ * ( )`).
local function is_name_byte(byte)
  return (byte >= 48 and byte <= 57)
    or (byte >= 65 and byte <= 90)
    or (byte >= 97 and byte <= 122)
    or byte == 95
    or byte == 45
    or byte == 58
    or byte == 46
    or byte == 91
    or byte == 93
    or byte == 64
    or byte == 42
    or byte == 40
    or byte == 41
end

--- Normalize an attribute name: `:class`, `v-bind:class`, `[class]`,
--- `className`, `class:list`, `ng-class` all become `class`.
--- @param name string
--- @return string|nil
local function attr_key(name)
  local key = name:lower()

  -- fast path: the overwhelmingly common spellings
  if key == "class" or key == "classname" or key == ":class" or key == "v-bind:class" or key == "ng-class" then
    return "class"
  end
  if key == "id" or key == ":id" or key == "v-bind:id" then
    return "id"
  end

  -- fast reject: every remaining class variant contains "class" in its name
  if not key:find("class", 1, true) then
    return nil
  end

  -- slow path for unusual variants (`[class]`, `*class`, `x-bind:class`, ...)
  key = key:gsub("^v%-bind:", ""):gsub("^x%-bind:", ""):gsub("^bind:", ""):gsub("^:", ""):gsub("^%*", "")
  key = key:gsub("^%[", ""):gsub("%]$", ""):gsub("^%(", ""):gsub("%)$", "")
  key = key:gsub("[%s_%-:]", "")

  if key == "class" or key == "classname" or key == "ngclass" or key == "classlist" then
    return "class"
  end
  if key == "id" then
    return "id"
  end
  return nil
end

--- @param token string
--- @return boolean
local function valid_token(token)
  local len = #token
  if len == 0 or len > 128 then
    return false
  end

  local numeric = true
  for i = 1, len do
    local byte = B(token, i)
    -- reject quotes, braces, `$`, `<`, `>`, backticks, ...
    if
      byte == 34
      or byte == 39
      or byte == 96
      or byte == 123
      or byte == 125
      or byte == 36
      or byte == 60
      or byte == 62
    then
      return false
    end
    if not (byte >= 48 and byte <= 57) then
      if byte ~= 46 and byte ~= 47 and byte ~= 37 and byte ~= 45 then
        numeric = false
      end
    end
  end

  -- ignore pure numbers/units (e.g. stray values from odd templates)
  return not numeric
end

--- Split `value` on whitespace and commas, appending tokens to `out`.
--- @param value string
--- @param out string[]
local function split_tokens(value, out)
  local start
  local len = #value
  for i = 1, len + 1 do
    if is_separator(B(value, i)) then
      if start then
        out[#out + 1] = SUB(value, start, i - 1)
        start = nil
      end
    elseif not start then
      start = i
    end
  end
end

--- Extract class names from an attribute value. Handles plain lists,
--- Vue array/object syntax (`:class="['a', ok && 'b']"`) and template
--- literals (backtick values are already captured by the main parser).
--- @param value string
--- @return string[]
local function class_tokens(value)
  local tokens = {}

  -- Dynamic values (Vue/JSX/Svelte) only contribute their quoted strings.
  if value:find("[\"']", 1) then
    local i = 1
    local len = #value
    while i <= len do
      local quote = QUOTE_CHARS[B(value, i)]
      if quote then
        local close = value:find(quote, i + 1, true)
        if not close then
          break
        end
        split_tokens(SUB(value, i + 1, close - 1), tokens)
        i = close + 1
      else
        i = i + 1
      end
    end
  else
    split_tokens(value, tokens)
  end

  return tokens
end

--- @param map table<string, { name: string, count: integer, files: table<string, true> }>
--- @param name string
--- @param path string
local function add(map, name, path)
  local entry = map[name]
  if not entry then
    entry = { name = name, count = 0, files = {} }
    map[name] = entry
  end
  entry.count = entry.count + 1
  entry.files[path] = true
end

--- @param map table<string, { name: string, count: integer, files: table<string, true> }>
--- @return { name: string, count: integer, files: string[] }[]
local function to_list(map)
  local list = {}
  for _, entry in pairs(map) do
    local files = vim.tbl_keys(entry.files)
    table.sort(files)
    list[#list + 1] = { name = entry.name, count = entry.count, files = files }
  end
  table.sort(list, function(a, b)
    if a.count ~= b.count then
      return a.count > b.count
    end
    return a.name < b.name
  end)
  return list
end

--- @param tokens string[]
--- @param map table
--- @param path string
--- @param max_entries integer
--- @param count integer number of unique entries already collected
--- @return integer count updated number of unique entries
local function add_tokens(tokens, map, path, max_entries, count)
  for _, token in ipairs(tokens) do
    if valid_token(token) then
      if map[token] then
        add(map, token, path)
      elseif count < max_entries then
        count = count + 1
        add(map, token, path)
      end
    end
  end
  return count
end

--- @param content string
--- @param path string
--- @param acc { classes: table, ids: table, class_count: integer, id_count: integer }
--- @param max_entries integer
local function parse_content(content, path, acc, max_entries)
  local len = #content
  local init = 1

  while true do
    local eq = content:find("=", init, true)
    if not eq then
      break
    end
    init = eq + 1

    -- attribute name: walk back over spaces, then over name bytes
    local name_end = eq - 1
    while name_end >= 1 and is_space(B(content, name_end)) do
      name_end = name_end - 1
    end
    local name_start = name_end
    while name_start >= 1 and is_name_byte(B(content, name_start)) do
      name_start = name_start - 1
    end
    name_start = name_start + 1

    if name_start <= name_end then
      local key = attr_key(SUB(content, name_start, name_end))
      if key then
        -- skip whitespace, then an optional `{` (JSX expressions)
        local pos = eq + 1
        while pos <= len and is_space(B(content, pos)) do
          pos = pos + 1
        end
        if B(content, pos) == 123 then
          pos = pos + 1
          while pos <= len and is_space(B(content, pos)) do
            pos = pos + 1
          end
        end

        local quote = QUOTE_CHARS[B(content, pos)]
        if quote then
          local close = content:find(quote, pos + 1, true)
          local line_end = content:find("\n", pos + 1, true) or (len + 1)
          -- values are single-line in practice; skip multi-line ones
          if close and close < line_end then
            local value = SUB(content, pos + 1, close - 1)
            if key == "class" then
              acc.class_count = add_tokens(class_tokens(value), acc.classes, path, max_entries, acc.class_count)
            else
              local tokens = class_tokens(value)
              if tokens[1] then
                acc.id_count = add_tokens({ tokens[1] }, acc.ids, path, max_entries, acc.id_count)
              end
            end
          end
        end
      end
    end
  end
end

--- @param set_list string[]
--- @return table<string, true>
local function make_set(set_list)
  local set = {}
  for _, item in ipairs(set_list or {}) do
    set[item:lower()] = true
  end
  return set
end

local function file_extension(path)
  return (path:match("%.([%w_]+)$") or ""):lower()
end

--- Scan `root` for class/id usages.
--- @param root string
--- @param config table
--- @return { classes: table[], ids: table[], files: integer, bytes: integer, root: string, scanned_at: integer }
function M.scan(root, config)
  local extensions = make_set(config.extensions)
  local ignore_dirs = make_set(config.ignore_dirs)

  local acc = { classes = {}, ids = {}, class_count = 0, id_count = 0 }
  local files_scanned = 0
  local bytes_read = 0

  -- DFS stack of { path, depth }
  local stack = { { root, 0 } }

  while #stack > 0 and files_scanned < config.max_files and bytes_read < config.max_total_bytes do
    local current = table.remove(stack)
    local dir, depth = current[1], current[2]

    local handle = uv.fs_scandir(dir)
    if handle then
      while files_scanned < config.max_files and bytes_read < config.max_total_bytes do
        local name, typ = uv.fs_scandir_next(handle)
        if not name then
          break
        end

        local path = dir .. "/" .. name
        if typ == nil then
          local stat = uv.fs_stat(path)
          typ = stat and stat.type or nil
        end

        if typ == "directory" then
          if depth + 1 <= config.max_depth and not ignore_dirs[name:lower()] then
            stack[#stack + 1] = { path, depth + 1 }
          end
        elseif typ == "file" then
          if extensions[file_extension(name)] then
            local stat = uv.fs_stat(path)
            if stat and stat.size and stat.size <= config.max_file_size then
              local fd = io.open(path, "r")
              if fd then
                local content = fd:read("*a")
                fd:close()
                if content then
                  bytes_read = bytes_read + #content
                  files_scanned = files_scanned + 1
                  -- cheap pre-filter: files without any `class`/`id` token
                  if content:find("class", 1, true) or content:find("id", 1, true) then
                    parse_content(content, path, acc, config.max_entries)
                  end
                end
              end
            end
          end
        end
        -- symlinks are intentionally ignored: avoids loops and duplicated files
      end
    end
  end

  return {
    classes = to_list(acc.classes),
    ids = to_list(acc.ids),
    files = files_scanned,
    bytes = bytes_read,
    root = root,
    scanned_at = uv.now(),
  }
end

-- exported for tests / other modules
M._attr_key = attr_key

return M
