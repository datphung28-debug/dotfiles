-- Declarative keymap helper used by the plugin modules.
---@param keymaps table[]
local function map(keymaps)
  for _, entry in ipairs(keymaps) do
    vim.keymap.set(entry.mode or "n", entry[1], entry[2], {
      desc = entry.desc,
      silent = entry.silent ~= false,
      remap = entry.remap or false,
      expr = entry.expr,
      nowait = entry.nowait,
      buffer = entry.buffer,
    })
  end
end

return map
