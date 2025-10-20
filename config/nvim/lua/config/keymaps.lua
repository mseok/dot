vim.g.mapleader = " "

vim.keymap.set({ "n", "v", "x" }, "<leader>o", "<Cmd>source %<CR>", { desc = "Source " .. vim.fn.expand("$MYVIMRC") })
vim.keymap.set({ "n", "v", "x" }, "<leader>O", "<Cmd>restart<CR>", { desc = "Restart vim." })

-- Keep these in VS Code mode too - they're useful for navigation
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- These are for native Neovim only
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Paste with no register deletion
vim.keymap.set("x", "<leader>p", '"_dP')

-- Yank to system clipboard
vim.keymap.set("n", "<leader>y", '"+y', { desc = "yank to system clipboard" })
vim.keymap.set("v", "<leader>y", '"+y', { desc = "yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "yank line to system clipboard" })

-- No register deletion
vim.keymap.set("n", "<leader>d", '"_d', { desc = "No register deletion" })
vim.keymap.set("v", "<leader>d", '"_d', { desc = "No register deletion" })

vim.keymap.set("n", "<leader>bp", "<cmd>bp<CR>", { desc = "buffer previous" })
vim.keymap.set("n", "<leader>bn", "<cmd>bn<CR>", { desc = "buffer next" })
vim.keymap.set("n", "<leader>bd", "<cmd>bd<CR>", { desc = "buffer delete" })

-- [,] mappings
vim.keymap.set("n", "[b", "<cmd>bp<CR>", { desc = "buffer previous" })
vim.keymap.set("n", "]b", "<cmd>bn<CR>", { desc = "buffer next" })
vim.keymap.set("n", "[t", "<cmd>tabprevious<CR>", { desc = "tab previous" })
vim.keymap.set("n", "]t", "<cmd>tabNext<CR>", { desc = "tab next" })

-- Add undo break-points
vim.keymap.set("i", ",", ",<c-g>u")
vim.keymap.set("i", ".", ".<c-g>u")
vim.keymap.set("i", ";", ";<c-g>u")

-- better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- marks
vim.keymap.set("n", "<leader>dm", ":delmarks ")

-- terminal
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

-- goto current file's directory
vim.keymap.set("n", "<leader>cd", function()
	vim.cmd("cd " .. vim.fn.expand("%:p:h"))
end, { desc = "Change to current file's directory" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Navigate to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Navigate to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Navigate to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Navigate to right window" })

vim.keymap.set("n", "<C-c>", "<cmd>noh<CR>", { desc = "Unset highlight" })
