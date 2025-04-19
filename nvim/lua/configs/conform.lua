local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    rust = { "rust-analyzer" },
    -- css = { "prettier" },
    -- html = { "prettier" },
    javascript = { "prettierd" },
    javascriptreact = { "prettierd" },
    typescript = { "prettierd" },
    typescriptreact = { "prettierd" },
    css = { "prettierd" },
    html = { "prettierd", "djlint" },
    markdown = { "prettierd" },
    c = { "clang-format" },
    cpp = { "clang-format" },
  },

  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
