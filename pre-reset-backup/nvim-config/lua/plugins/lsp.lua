-- mason chain + native vim.lsp API (nvim-lspconfig is data-only now)
return {
  { "mason-org/mason.nvim", opts = {} },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = {
        "prettierd",
        "stylua",
        "eslint_d",
        "tree-sitter-cli",
      },
    },
  },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
      "saghen/blink.cmp",
    },
    opts = {
      ensure_installed = {
        "vtsls",
        "tailwindcss",
        "eslint",
        "emmet_language_server",
        "jsonls",
        "yamlls",
        "lua_ls",
        "marksman",
        -- NOTE: swap vtsls -> tsgo/tsc later for the faster native TS server.
      },
      automatic_enable = true,
    },
    config = function(_, opts)
      require("mason-lspconfig").setup(opts)
      -- blink capabilities for every server
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
      end
    end,
  },

  { "neovim/nvim-lspconfig" },
}
