-- general maps (plugin maps live in their specs)
local map = vim.keymap.set

map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit window" })

map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- C-h/j/k/l owned by vim-tmux-navigator (normal + terminal modes)
-- window resizing (normal mode)
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Grow window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Shrink window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Shrink window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Grow window width" })

-- same resizing from terminal mode (no Esc dance: drops to normal, resizes, jumps back in)
map("t", "<C-Up>", "<C-\\><C-n><cmd>resize +2<cr>i", { desc = "Grow window height" })
map("t", "<C-Down>", "<C-\\><C-n><cmd>resize -2<cr>i", { desc = "Shrink window height" })
map("t", "<C-Left>", "<C-\\><C-n><cmd>vertical resize -2<cr>i", { desc = "Shrink window width" })
map("t", "<C-Right>", "<C-\\><C-n><cmd>vertical resize +2<cr>i", { desc = "Grow window width" })

-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

map("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Prev search result" })

-- move lines in visual mode
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
map("n", "<leader>e", "<cmd>Oil --float<cr>", { desc = "Oil floating explorer" })

map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
