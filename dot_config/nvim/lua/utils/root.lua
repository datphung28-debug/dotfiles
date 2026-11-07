-- Project root detection shared by the statusline, pickers and lazygit.
-- Prefers the LSP workspace (works for monorepos, C projects, ...) and falls
-- back to well-known project markers, then to the current directory.
local M = {}

local markers = { ".git", "lua", "package.json", "Makefile", "Cargo.toml", "go.mod", "pyproject.toml" }

---@param path string?
---@return string?
local function normalize(path)
  if not path or path == "" then
    return nil
  end
  path = vim.uv.fs_realpath(path) or path
  return (path:gsub("/$", ""))
end

---@param buf number
---@return string?
local function lsp_root(buf)
  local path = normalize(vim.api.nvim_buf_get_name(buf))
  if not path then
    return nil
  end

  local best
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    local roots = {}
    for _, ws in ipairs(client.workspace_folders or {}) do
      roots[#roots + 1] = vim.uri_to_fname(ws.uri)
    end
    if client.root_dir then
      roots[#roots + 1] = client.root_dir
    end
    for _, root in ipairs(roots) do
      root = normalize(root)
      if root and vim.startswith(path, root) and (not best or #root > #best) then
        best = root
      end
    end
  end
  return best
end

---@param opts? { buf?: number }
---@return string
function M.get(opts)
  opts = opts or {}
  local buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf

  local root = lsp_root(buf) or vim.fs.root(buf, markers)
  return normalize(root) or normalize(vim.uv.cwd()) or vim.fn.getcwd()
end

-- Root of the enclosing git repository (for lazygit and git pickers).
function M.git()
  local root = M.get()
  local git_root = vim.fs.find(".git", { path = root, upward = true })[1]
  return git_root and vim.fn.fnamemodify(git_root, ":h") or root
end

return M
