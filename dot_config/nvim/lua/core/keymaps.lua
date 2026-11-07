-- Builtin keymaps only. Plugin keymaps live next to the plugin setup.
local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Do things without updating the registers
keymap.set("n", "x", '"_x')
keymap.set("n", "<Leader>p", '"0p')
keymap.set("n", "<Leader>P", '"0P')
keymap.set("v", "<Leader>p", '"0p')
keymap.set("n", "<Leader>c", '"_c')
keymap.set("n", "<Leader>C", '"_C')
keymap.set("v", "<Leader>c", '"_c')
keymap.set("v", "<Leader>C", '"_C')
keymap.set("n", "<Leader>d", '"_d')
keymap.set("n", "<Leader>D", '"_D')
keymap.set("v", "<Leader>d", '"_d')
keymap.set("v", "<Leader>D", '"_D')

-- Delete a word backwards
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Clear search highlight
keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear Highlight", silent = true })

-- Fast move lines
keymap.set("n", "K", "5k", opts)
keymap.set("n", "J", "5j", opts)
keymap.set("v", "K", "5k", opts)
keymap.set("v", "J", "5j", opts)

-- Increment/Decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Disable continuations
keymap.set("n", "<Leader>o", "o<Esc>^Da", opts)
keymap.set("n", "<Leader>O", "O<Esc>^Da", opts)

keymap.set("n", "<leader>nt", "<cmd>tabnew<cr>", { desc = "New Tab" })
keymap.set("n", "<tab>", ":tabnext<CR>", opts)
keymap.set("n", "<s-tab>", ":tabprev<CR>", opts)
keymap.set("n", "<leader>-", "<cmd>split<cr>", { desc = "Split Window Below" })
keymap.set("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Split Window Right" })

-- Move window
keymap.set("n", "<C-h>", "<C-w>h")
keymap.set("n", "<C-k>", "<C-w>k")
keymap.set("n", "<C-j>", "<C-w>j")
keymap.set("n", "<C-l>", "<C-w>l")

-- Move lines up/down, keeping the selection in visual mode
keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
keymap.set("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- window navigation
keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Height" })
keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Height" })
keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Width" })
keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Width" })

-- wrapped line navigation
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up (wrapped)" })
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down (wrapped)" })

-- Keep search direction and center the match
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Match" })
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Match" })
vim.keymap.set({ "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Match" })
vim.keymap.set({ "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Match" })
vim.keymap.set("n", "*", "*zzzv", { desc = "Search Word (centered)" })
vim.keymap.set("n", "#", "#zzzv", { desc = "Search Word Back (centered)" })

-- Better indenting (stay in visual mode)
vim.keymap.set("v", "<", "<gv", { desc = "Indent Left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent Right" })

-- Select all
vim.keymap.set("n", "<leader>h", "ggVG", { desc = "Select All" })

-- Add an undo break-point while typing
vim.keymap.set("i", ",", ",<c-g>u", { desc = "Undo break-point" })
vim.keymap.set("i", ".", ".<c-g>u", { desc = "Undo break-point" })
vim.keymap.set("i", ";", ";<c-g>u", { desc = "Undo break-point" })

-- Comment below/above without moving the text
vim.keymap.set("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
-- vim.keymap.set("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- Diagnostics
local diagnostic_jump = function(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
keymap.set("n", "]d", diagnostic_jump(true), { desc = "Next Diagnostic" })
keymap.set("n", "[d", diagnostic_jump(false), { desc = "Prev Diagnostic" })
keymap.set("n", "]e", diagnostic_jump(true, "ERROR"), { desc = "Next Error" })
keymap.set("n", "[e", diagnostic_jump(false, "ERROR"), { desc = "Prev Error" })
keymap.set("n", "]w", diagnostic_jump(true, "WARN"), { desc = "Next Warning" })
keymap.set("n", "[w", diagnostic_jump(false, "WARN"), { desc = "Prev Warning" })

-- Quickfix list navigation (Trouble has the full list in <leader>xQ)
local function qf_nav(cmd)
  return function()
    local ok, err = pcall(vim.cmd, cmd)
    if not ok then
      vim.notify(err, vim.log.levels.WARN)
    end
  end
end
keymap.set("n", "[q", qf_nav("cprev"), { desc = "Previous Quickfix" })
keymap.set("n", "]q", qf_nav("cnext"), { desc = "Next Quickfix" })

-- Redraw / clear search / update diffs
keymap.set("n", "<leader>ur", "<cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><cr>", { desc = "Redraw" })

-- Terminal
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit Terminal Mode" })
vim.keymap.set("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go Left" })
vim.keymap.set("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go Down" })
vim.keymap.set("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go Up" })
vim.keymap.set("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go Right" })

-- Yank current file path
keymap.set("n", "<Leader>yf", function()
  require("utils.editor").yank_relative_path_with_line()
end, { desc = "Yank relative path with line number" })

keymap.set("n", "<Leader>yp", function()
  require("utils.editor").yank_absolute_path_with_line()
end, { desc = "Yank absolute path with line number" })

keymap.set("n", "<Leader>j", function()
  require("utils.editor").open_package_json()
end, { desc = "Open package.json in floating window" })
