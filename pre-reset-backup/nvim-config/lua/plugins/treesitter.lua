-- nvim-treesitter main branch + treesitter-modules (old configs.setup is gone)
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    dependencies = { "MeanderingProgrammer/treesitter-modules.nvim" },
    config = function()
      require("treesitter-modules").setup({
        ensure_installed = {
          "typescript",
          "tsx",
          "javascript",
          "jsdoc",
          "json",
          "css",
          "html",
          "yaml",
          "toml",
          "lua",
          "luadoc",
          "vim",
          "vimdoc",
          "markdown",
          "markdown_inline",
          "sql",
          "dockerfile",
          "bash",
          "regex",
        },
        highlight = { enable = true },
        indent = { enable = true },
        fold = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
          },
        },
      })
    end,
  },
}
