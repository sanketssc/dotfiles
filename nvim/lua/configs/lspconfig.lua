require("nvchad.configs.lspconfig").defaults()
local lspconfig = require("lspconfig")
local on_attach = require("nvchad.configs.lspconfig").on_attach
local capabilities = require("nvchad.configs.lspconfig").capabilities
local util = require("lspconfig/util")
local on_init = require("nvchad.configs.lspconfig").on_init

local servers = { "html", "cssls" }
vim.lsp.enable(servers)

lspconfig.rust_analyzer.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {"rust"},
  root_dir = util.root_pattern("Cargo.toml"),
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        allFeatures = true,
      }
    }
  }
}

-- c & cpp setup
lspconfig.clangd.setup {
  on_attach = function(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
    on_attach(client, bufnr)
  end,
  on_init = on_init,
  capabilities = capabilities,
}
