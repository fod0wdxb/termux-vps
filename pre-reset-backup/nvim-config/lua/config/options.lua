-- base options (2-space indent matches prettier)
local o = vim.opt

o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"
o.termguicolors = true

o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 2
o.expandtab = true
o.smartindent = true
o.breakindent = true

o.wrap = false
o.scrolloff = 8
o.sidescrolloff = 8

o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = true

o.splitright = true
o.splitbelow = true

o.updatetime = 200
o.timeoutlen = 300
o.ttimeoutlen = 10

o.undofile = true
o.swapfile = false
o.backup = false
o.writebackup = false

o.mouse = "a"
o.clipboard = "unnamedplus"
o.completeopt = { "menuone", "noselect", "popup" }
o.pumheight = 10
o.showmode = false
o.cmdheight = 1
o.laststatus = 3
o.confirm = true

o.winborder = "rounded"

-- unused providers off (faster startup; re-enable if a plugin needs one)
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- fold via treesitter
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevel = 99
o.foldlevelstart = 99
