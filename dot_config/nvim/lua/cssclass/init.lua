-- cssclass
--
-- Local plugin: recommends CSS class names and ids, collected from the markup
-- files of the current project, through blink.cmp.
--
--   ./btn|  ->  .btn, .btn-primary, ...
--   #app|   ->  #app, #app-root, ...
--
-- It is also able to complete inside `class="..."` / `id="..."` attributes of
-- markup buffers (HTML, Vue, Svelte, JSX, ...). Disable that with
-- `markup_attributes = false`.
--
-- Commands:
--   :CssClassRefresh  drop the cache, rescan on next completion
--   :CssClassList     show detected classes/ids in the quickfix list
local M = {}

local uv = vim.uv or vim.loop

local defaults = {
  -- filetypes where `.foo` / `#foo` selectors are completed
  filetypes = { "css", "scss", "sass", "less", "stylus", "postcss", "pcss" },

  -- filetypes where class="..." / id="..." values are completed
  markup_filetypes = {
    "html",
    "xhtml",
    "vue",
    "svelte",
    "astro",
    "php",
    "blade",
    "htmlangular",
    "htmldjango",
    "javascriptreact",
    "typescriptreact",
    "mdx",
    "templ",
    "heex",
    "eruby",
    "liquid",
    "twig",
    "handlebars",
  },

  -- file extensions scanned for class/id usages
  extensions = {
    "html",
    "htm",
    "xhtml",
    "vue",
    "svelte",
    "astro",
    "php",
    "phtml",
    "jsx",
    "tsx",
    "js",
    "ts",
    "mjs",
    "cjs",
    "md",
    "mdx",
    "erb",
    "ejs",
    "hbs",
    "handlebars",
    "twig",
    "liquid",
    "njk",
    "heex",
    "templ",
  },

  -- directories never scanned
  ignore_dirs = {
    ".git",
    ".hg",
    ".svn",
    ".next",
    ".nuxt",
    ".svelte-kit",
    ".astro",
    ".vercel",
    ".output",
    ".turbo",
    ".cache",
    ".yarn",
    ".pnpm-store",
    "node_modules",
    "bower_components",
    "vendor",
    "dist",
    "build",
    "out",
    "coverage",
    "target",
    "venv",
    ".venv",
    "__pycache__",
    ".idea",
    ".vscode",
    "tmp",
    ".tmp",
    "storage",
  },

  max_files = 600,
  max_file_size = 1024 * 1024,
  max_total_bytes = 16 * 1024 * 1024,
  max_depth = 20,
  -- maximum number of unique class names / ids kept in memory
  max_entries = 4000,

  -- milliseconds before the cache is considered stale.
  -- 0 = keep the cache until a markup file is saved / :CssClassRefresh is run
  cache_ttl = 0,

  -- complete class/id values inside markup attributes
  markup_attributes = true,

  -- optional: function(bufnr) -> project root
  get_root = nil,
}

M.config = vim.deepcopy(defaults)

--- @type table<string, { classes: table[], ids: table[], files: integer, bytes: integer, root: string, scanned_at: integer }>
local cache = {}

--- Resolved project root per starting directory (see `M.get_root`).
--- @type table<string, string>
local root_cache = {}

-- File extensions that make a directory look like a project root when there is
-- no marker (`.git`, `package.json`, ...). Only markup files: a stray `.js` or
-- `.md` file in a parent directory should not win over the real site root.
local ROOT_MARKUP_EXTENSIONS = {
  html = true,
  htm = true,
  xhtml = true,
  vue = true,
  svelte = true,
  astro = true,
  jsx = true,
  tsx = true,
  php = true,
  phtml = true,
  erb = true,
  ejs = true,
  hbs = true,
  handlebars = true,
  twig = true,
  liquid = true,
  njk = true,
  heex = true,
  templ = true,
}

--- @param list string[]
--- @return table<string, true>
local function make_set(list)
  local set = {}
  for _, item in ipairs(list) do
    set[item:lower()] = true
  end
  return set
end

--- Does `dir` directly contain a markup file?
--- @param dir string
--- @return boolean
local function dir_has_markup(dir)
  local handle = uv.fs_scandir(dir)
  if not handle then
    return false
  end

  while true do
    local name, typ = uv.fs_scandir_next(handle)
    if not name then
      return false
    end
    if typ == "file" or typ == nil then
      local ext = (name:match("%.([%w_]+)$") or ""):lower()
      if ROOT_MARKUP_EXTENSIONS[ext] then
        return true
      end
    end
  end
end

--- Walk up from `dir` until a directory that directly contains markup files is
--- found. This is what makes `<project>/css/style.css` resolve to `<project>`
--- even when the project has no `.git` / `package.json` marker.
--- @param dir string
--- @return string|nil
local function find_markup_root(dir)
  for _ = 1, 32 do
    if dir_has_markup(dir) then
      return dir
    end
    local parent = vim.fs.dirname(dir)
    if parent == nil or parent == "" or parent == dir then
      return nil
    end
    dir = parent
  end
end

--- @param dir string
--- @param child string
--- @return boolean
local function is_ancestor(dir, child)
  dir = vim.fs.normalize(dir):gsub("/$", "")
  child = vim.fs.normalize(child):gsub("/$", "")
  return child == dir or child:sub(1, #dir + 1) == dir .. "/"
end

local function build_sets()
  M.config.filetypes_set = make_set(M.config.filetypes)
  M.config.markup_filetypes_set = M.config.markup_attributes and make_set(M.config.markup_filetypes) or {}
  M.config.extensions_set = make_set(M.config.extensions)
end

build_sets()

--- @param bufnr? integer
--- @return string
function M.get_root(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- user override always wins and is not cached
  if type(M.config.get_root) == "function" then
    local ok, root = pcall(M.config.get_root, bufnr)
    if ok and type(root) == "string" and root ~= "" then
      return root
    end
  end

  local name = vim.api.nvim_buf_get_name(bufnr)

  -- unnamed buffer: use the working directory
  if name == "" then
    return vim.fn.getcwd()
  end

  local start_dir = vim.fs.dirname(name)
  local cached = root_cache[start_dir]
  if cached then
    return cached
  end

  local root
  local ok, marker_root = pcall(vim.fs.root, bufnr, {
    ".git",
    "package.json",
    "composer.json",
    "vite.config.js",
    "vite.config.ts",
    "tsconfig.json",
    "pyproject.toml",
    "Cargo.toml",
    "go.mod",
    "Gemfile",
    "mix.exs",
  })

  if ok and marker_root then
    root = marker_root
  else
    -- No project marker. Walk up to the nearest directory containing markup
    -- files so that `css/style.css` finds a sibling `index.html` at the root.
    root = find_markup_root(start_dir)

    -- Fall back to the working directory when the file lives inside it.
    if not root then
      local cwd = vim.fn.getcwd()
      if is_ancestor(cwd, start_dir) then
        root = cwd
      end
    end

    root = root or start_dir
  end

  root_cache[start_dir] = root
  return root
end

--- @param bufnr? integer
--- @return { classes: table[], ids: table[], files: integer, bytes: integer, root: string, scanned_at: integer }
function M.get_entries(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local root = M.get_root(bufnr)

  local ttl = M.config.cache_ttl
  local cached = cache[root]
  if cached and (ttl <= 0 or (uv.now() - cached.scanned_at) < ttl) then
    return cached
  end

  local result = require("cssclass.scanner").scan(root, M.config)
  cache[root] = result
  return result
end

--- @param bufnr? integer
function M.invalidate(bufnr)
  cache[M.get_root(bufnr or vim.api.nvim_get_current_buf())] = nil
end

function M.invalidate_all()
  for root in pairs(cache) do
    cache[root] = nil
  end
  for dir in pairs(root_cache) do
    root_cache[dir] = nil
  end
end

--- @param opts? table
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  build_sets()
  M.invalidate_all()

  vim.api.nvim_create_user_command("CssClassRefresh", function()
    M.invalidate_all()
    vim.notify("cssclass: cache cleared, project will be rescanned", vim.log.levels.INFO)
  end, { desc = "Clear the CSS class/id cache" })

  vim.api.nvim_create_user_command("CssClassList", function()
    local entries = M.get_entries(0)
    local lines = {}
    for _, entry in ipairs(entries.classes) do
      lines[#lines + 1] = ("class .%s (%d)"):format(entry.name, entry.count)
    end
    for _, entry in ipairs(entries.ids) do
      lines[#lines + 1] = ("id #%s (%d)"):format(entry.name, entry.count)
    end

    vim.fn.setqflist({}, " ", { title = "cssclass", lines = lines })
    vim.notify(
      ("cssclass: %d classes, %d ids from %d files"):format(#entries.classes, #entries.ids, entries.files),
      vim.log.levels.INFO
    )
  end, { desc = "List detected CSS classes/ids in the quickfix list" })

  local group = vim.api.nvim_create_augroup("CssClassCache", { clear = true })

  -- Re-scan after a markup file is saved, so newly added classes show up.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(args)
      local ext = vim.fn.fnamemodify(args.file, ":e"):lower()
      if M.config.extensions_set[ext] then
        M.invalidate(args.buf)
      end
    end,
    desc = "Invalidate cssclass cache after saving a markup file",
  })

  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = M.invalidate_all,
    desc = "Invalidate cssclass cache after changing directory",
  })

  -- Pick up changes made outside Neovim (git pull, another editor, ...).
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = M.invalidate_all,
    desc = "Invalidate cssclass cache when Neovim regains focus",
  })
end

return M
