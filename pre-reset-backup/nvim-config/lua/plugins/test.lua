-- neotest + vitest + todo-comments
return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "antoinemadec/FixCursorHold.nvim",
      "marilari88/neotest-vitest",
    },
    keys = {
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
      { "<leader>tn", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test output" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-vitest")({
            filter_dir = function(name)
              return name ~= "node_modules"
            end,
          }),
        },
        status = { virtual_text = true },
        output = { open_on_run = true },
      })
    end,
  },
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      { "<leader>st", "<cmd>TodoQuickFix<cr>", desc = "TODOs" },
    },
  },
}
