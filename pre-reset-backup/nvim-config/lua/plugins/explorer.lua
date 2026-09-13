-- oil.nvim file explorer. lazy=false (lazy-loading breaks it).
return {
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { { "nvim-mini/mini.icons", opts = {} } },
    ---@module "oil"
    ---@type oil.SetupOpts
    opts = {
      default_file_explorer = true,
      columns = { "icon" },
      lsp_file_methods = { enabled = true, timeout_ms = 1000 },
      constrain_cursor = "editable",
      -- translucent float (0 opaque - 100 invisible, text included)
      float = { win_options = { winblend = 20 } },
      -- dotfiles visible; `g.` toggles. .git/node_modules/dist always hidden.
      view_options = {
        show_hidden = true,
        is_always_hidden = function(name)
          return name == ".git" or name == "node_modules" or name == "dist"
        end,
      },
    },
  },
}
