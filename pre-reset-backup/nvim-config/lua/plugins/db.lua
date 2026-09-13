-- Neon/Postgres browser
return {
  {
    "tpope/vim-dadbod",
    cmd = { "DB", "DBUI" },
    dependencies = {
      { "kristijanhusak/vim-dadbod-ui" },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" } },
    },
    keys = {
      { "<leader>Du", "<cmd>DBUIToggle<cr>", desc = "DB UI toggle" },
    },
  },
}
