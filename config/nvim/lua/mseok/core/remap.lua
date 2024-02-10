vim.g.mapleader = " "

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste with no register deletion
vim.keymap.set("x", "<leader>p", "\"_dP")

-- Yank to system clipboard
vim.keymap.set("n", "<leader>y", "\"+y", { desc = "yank to system clipboard" })
vim.keymap.set("v", "<leader>y", "\"+y", { desc = "yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", "\"+Y", { desc = "yank line to system clipboard" })

-- No register deletion
vim.keymap.set("n", "<leader>d", "\"_d", { desc = "No register deletion" })
vim.keymap.set("v", "<leader>d", "\"_d", { desc = "No register deletion" })

vim.keymap.set("n", "<leader>bp", "<cmd>bp<CR>", { desc = "buffer previous" })
vim.keymap.set("n", "<leader>bn", "<cmd>bn<CR>", { desc = "buffer next" })
vim.keymap.set("n", "<leader>bd", "<cmd>bd<CR>", { desc = "buffer delete" })

-- [,] mappings
vim.keymap.set("n", "[b", "<cmd>bp<CR>", { desc = "buffer previous" })
vim.keymap.set("n", "]b", "<cmd>bn<CR>", { desc = "buffer next" })
vim.keymap.set("n", "[t", "<cmd>tabprevious<CR>", { desc = "tab previous" })
vim.keymap.set("n", "]t", "<cmd>tabNext<CR>", { desc = "tab next" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
