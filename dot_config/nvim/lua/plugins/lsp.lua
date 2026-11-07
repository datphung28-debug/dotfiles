-- LSP: mason tooling, vim.lsp setup (configs live in after/lsp/), keymaps.
require("mason").setup()
require("mason-tool-installer").setup({
  ensure_installed = {
    "lua-language-server",
    "prettier",
    "prettierd",
    "shellcheck",
    "shfmt",
    "stylua",
    "eslint-lsp",
    "oxlint",
    "oxfmt",
    "tailwindcss-language-server",
    "vtsls",
    "clangd",
    "css-lsp",
    "html-lsp",
    "json-lsp",
    "emmet-language-server",
    "vue-language-server",
    "svelte-language-server",
  },
  auto_update = false,
  run_on_start = true,
})

-- Live preview for LSP rename (`:IncRename`)
require("inc_rename").setup({})

local capabilities = {
  workspace = {
    fileOperations = {
      didRename = true,
      willRename = true,
    },
  },
}
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(capabilities),
})

vim.lsp.enable({
  "lua_ls",
  "cssls",
  "vtsls",
  "oxlint",
  "eslint",
  "clangd",
  "html",
  "emmet_language_server",
  "vue_ls",
  "tailwindcss",
  "jsonls",
  "svelte",
})

-- Keymaps are buffer-local and only exist while an LSP client is attached,
-- so they never shadow the builtin fallbacks in plain buffers.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
  callback = function(ev)
    local buf = ev.buf

    local function map(mode, lhs, rhs, desc, expr)
      vim.keymap.set(mode, lhs, rhs, {
        buffer = buf,
        desc = desc,
        silent = true,
        expr = expr,
      })
    end

    -- Navigation
    map("n", "gd", function()
      require("snacks").picker.lsp_definitions({ jump = { reuse_win = false } })
    end, "LSP Goto Definition")
    map("n", "gD", function()
      require("snacks").picker.lsp_declarations()
    end, "LSP Goto Declaration")
    map("n", "gy", function()
      require("snacks").picker.lsp_type_definitions()
    end, "LSP Goto T[y]pe Definition")
    map("n", "gr", function()
      require("snacks").picker.lsp_references()
    end, "LSP References")
    map("n", "gI", function()
      local clients = vim.lsp.get_clients({ bufnr = 0, name = "vtsls" })
      if #clients > 0 then
        local params = vim.lsp.util.make_position_params(0, "utf-16")
        clients[1]:request("workspace/executeCommand", {
          command = "typescript.goToSourceDefinition",
          arguments = { params.textDocument.uri, params.position },
        }, function(err, result)
          if err then
            vim.notify("goToSourceDefinition: " .. err.message, vim.log.levels.ERROR)
            return
          end
          if result and #result > 0 then
            vim.lsp.util.show_document(result[1], "utf-16", { focus = true })
          else
            vim.notify("No source definition found", vim.log.levels.INFO)
          end
        end, 0)
      else
        vim.lsp.buf.implementation()
      end
    end, "Goto Source Definition / Implementation")

    -- Info (J/K keep their 5-line scroll from core/keymaps.lua)
    map("n", "<leader>ch", vim.lsp.buf.hover, "Hover")
    map("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
    map("i", "<c-k>", vim.lsp.buf.signature_help, "Signature Help")

    -- Actions
    map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
    map({ "n", "x" }, "<leader>cc", vim.lsp.codelens.run, "Run Codelens")
    map("n", "<leader>cC", vim.lsp.codelens.refresh, "Refresh & Display Codelens")
    map("n", "<leader>co", function()
      vim.lsp.buf.code_action({
        apply = true,
        context = { only = { "source.organizeImports" }, diagnostics = {} },
      })
    end, "Organize Imports")
    map({ "n", "x" }, "<leader>cA", function()
      vim.lsp.buf.code_action({
        apply = true,
        context = { only = { "source" }, diagnostics = {} },
      })
    end, "Source Action")
    map("n", "<leader>rn", function()
      return ":IncRename " .. vim.fn.expand("<cword>")
    end, "Rename", true)

    -- Inlay hints when the server supports them (vue_ls is too noisy)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if
      client
      and client:supports_method("textDocument/inlayHint")
      and vim.bo[buf].filetype ~= "vue"
      and vim.lsp.inlay_hint
    then
      vim.lsp.inlay_hint.enable(true, { bufnr = buf })
    end
  end,
})
