---@type vim.lsp.Config
local vue_ts_plugin = (vim.env.MASON or (vim.fn.stdpath("data") .. "/mason"))
  .. "/packages/vue-language-server/node_modules/@vue/language-server"

return {
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  on_attach = function(client)
    if client and client.server_capabilities.semanticTokensProvider then
      client.server_capabilities.semanticTokensProvider.range = false
    end
  end,
  settings = {
    complete_function_calls = true,
    vtsls = {
      enableMoveToFileCodeAction = true,
      autoUseWorkspaceTsdk = true,
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = vue_ts_plugin,
            languages = { "vue" },
            configNamespace = "typescript",
          },
        },
      },
      experimental = {
        maxInlayHintLength = 30,
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = {
        completeFunctionCalls = true,
      },
      preferences = {
        useAliasesForRenames = false,
      },
      inlayHints = {
        enumMemberValues = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        variableTypes = { enabled = false },
      },
    },
  },
}
