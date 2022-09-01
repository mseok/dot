local api = vim.api
local cmd = vim.cmd
local g   = vim.g

function custom_map(mode, lhs, rhs, opts)
  local options = {noremap = true}
  if opts then options = vim.tbl_extend("force", options, opts) end
  api.nvim_set_keymap(mode, lhs, rhs, options)
end

local scopes = {o = vim.o, b = vim.bo, w = vim.wo}
function toggle(scope, key)
  local value = scopes[scope][key]
  if type(value) == "boolean" then scopes[scope][key] = not(value) end
end

function toggle_term()
  local winheight = vim.fn.winheight(0)
  local termsize = (winheight / 3)
  cmd("bel split | resize " .. termsize .. " | term")
end

function autosize_netrw()
  cmd("tabe")
  local winwidth = vim.fn.winwidth(0)
  local termsize = (winwidth / 5)
  cmd("tabclose")
  cmd("leftabove vs . | vert resize " .. termsize)
end

-- Leader
g.mapleader = " "

-- Gitsings
custom_map("n", "<leader>gh", ":Gitsigns preview_hunk<CR>")
custom_map("n", "<leader>gp", ":Gitsigns prev_hunk<CR>")
custom_map("n", "<leader>gn", ":Gitsigns next_hunk<CR>")

-- Open dot files
custom_map("n", "<leader>,v", ":vsplit $HOME/dot/.config/nvim/init.lua<CR>")
custom_map("n", "<leader>,s", ":split $HOME/dot/.config/nvim/init.lua<CR>")

-- Terminal
custom_map("t", "<ESC>", "<C-\\><C-n>")
custom_map("n", "gt", ":lua toggle_term()<CR>")

-- Buffer
custom_map("n", "<C-n>", ":bn<CR>", {noremap = true})
custom_map("n", "<C-p>", ":bp<CR>", {noremap = true})
custom_map("n", "<leader>bd", ":bd<CR>", {noremap = true})
custom_map("x", "K", ":move '<-2<CR>gv-gv")
custom_map("x", "K", ":move '>+1<CR>gv-gv")
custom_map("n", "<C-g>", ":lua print(vim.fn.expand('%:p'))<CR>")

-- Dashboard
custom_map("n", "<leader>nf", ":DashboardNewFile<CR>", {noremap = true})

-- Telescope
custom_map("n", "<leader>fh", ":Telescope oldfiles hidden=true<CR>", {noremap = true})
custom_map("n", "<leader>ff", ":Telescope find_files hidden=true<CR>", {noremap = true})
custom_map("n", "<leader>fd", ":Telescope find_files hidden=true cwd=$HOME/dot/.config/nvim<CR>", {noremap = true})

-- netrw
custom_map("n", "<leader>dd", ":Lexplore %:p:h<CR>")
custom_map("n", "<leader>da", ":Lexplore <CR>")

vim.api.nvim_exec([[
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

function copy_mode()
  vim.api.nvim_command("Gitsigns toggle_signs")
end

custom_map("n", "<leader>cp", ":lua copy_mode()<CR>")
custom_map("n", "<leader>sb", ":lua toggle('w', 'scrollbind')<CR>")
