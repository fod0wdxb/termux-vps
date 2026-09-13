-- which-key, lualine, tmux navigator
return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-mini/mini.icons" },
    opts = { options = { theme = "auto", globalstatus = true } },
  },
  {
    -- seamless C-h/j/k/l with tmux panes (christoomey plugin both sides)
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
}
