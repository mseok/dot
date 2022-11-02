local api = vim.api
local cmd = vim.cmd
local g = vim.g
local keymap = vim.keymap

-- Util functions
function toggle_term()
  local winheight = vim.fn.winheight(0)
  local termsize = (winheight / 3)
  cmd("bel split | resize " .. termsize .. " | term")
end

function copy_mode()
  api.nvim_command("Gitsigns toggle_signs")
  vim.opt.number = not(vim.o.number)
  vim.opt.relativenumber = not(vim.o.relativenumber)
end

-- Leader
g.mapleader = " "

-- Gitsings
keymap.set("n", "<leader>gh", ":Gitsigns preview_hunk<CR>")
keymap.set("n", "<leader>gp", ":Gitsigns prev_hunk<CR>")
keymap.set("n", "<leader>gn", ":Gitsigns next_hunk<CR>")

-- Open dot files
keymap.set("n", "<leader>,v", ":vsplit $HOME/dot/.config/nvim/init.lua<CR>")
keymap.set("n", "<leader>,s", ":split $HOME/dot/.config/nvim/init.lua<CR>")

-- Terminal
keymap.set("t", "<ESC>", "<C-\\><C-n>")
keymap.set("n", "gt", ":lua toggle_term()<CR>")

-- Buffer
keymap.set("n", "<C-n>", ":bn<CR>", {noremap = true})
keymap.set("n", "<C-p>", ":bp<CR>", {noremap = true})
keymap.set("n", "<leader>bd", ":bd<CR>", {noremap = true})
keymap.set("n", "<C-g>", ":lua print(vim.fn.expand('%:p'))<CR>")

-- Dashboard
keymap.set("n", "<leader>nf", ":DashboardNewFile<CR>", {noremap = true})

-- Telescope
keymap.set("n", "<leader>fh", ":Telescope oldfiles hidden=true<CR>", {noremap = true})
keymap.set("n", "<leader>ff", ":Telescope find_files hidden=true<CR>", {noremap = true})
keymap.set("n", "<leader>fd", ":Telescope find_files hidden=true cwd=$HOME/dot/.config/nvim<CR>", {noremap = true})

-- Netrw
keymap.set("n", "<leader>dd", ":Lexplore %:p:h<CR>")
keymap.set("n", "<leader>da", ":Lexplore <CR>")

keymap.set("n", "<leader>cp", ":lua copy_mode()<CR>")

api.nvim_exec([[
  cnoreabbrev W! w!
  cnoreabbrev Q! q!
  cnoreabbrev Qall! qall!
  cnoreabbrev Wq wq
  cnoreabbrev Wa wa
  cnoreabbrev wQ wq
  cnoreabbrev WQ wq
  cnoreabbrev W w
  cnoreabbrev Q q
  cnoreabbrev Qall qall
]], false)

