local api = vim.api
local cmd = vim.cmd
local g   = vim.g

function custom_map(mode, lhs, rhs, opts)
  local options = {noremap = true}
  if opts then options = vim.tbl_extend("force", options, opts) end
  api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Leader
g.mapleader = " "

custom_map("n", "<leader>gh", ":Gitsigns preview_hunk<CR>")
custom_map("n", "<leader>gp", ":Gitsigns prev_hunk<CR>")
custom_map("n", "<leader>gn", ":Gitsigns next_hunk<CR>")
custom_map("n", "<C-s>", ":source $HOME/dot/.config/nvim/init.lua<CR>")
custom_map("n", "<leader>,v", ":vsplit $HOME/dot/.config/nvim/init.lua<CR>")
custom_map("n", "<leader>,s", ":split $HOME/dot/.config/nvim/init.lua<CR>")
custom_map("n", "<leader><leader>", ":Explore<CR>")
custom_map("n", "<leader>g", ":Gitsigns preview_hunk<CR>")
custom_map("n", "<leader>gn", ":Gitsigns next_hunk<CR>")
custom_map("n", "<leader>gp", ":Gitsigns prev_hunk<CR>")
custom_map("n", "Y", "y$")
custom_map("x", "K", ":move '<-2<CR>gv-gv")
custom_map("x", "K", ":move '>+1<CR>gv-gv")

-- Buffer
custom_map("n", "<C-n>", ":bn<CR>", {noremap = true})
custom_map("n", "<C-p>", ":bp<CR>", {noremap = true})
custom_map("n", "<leader>bd", ":bd<CR>", {noremap = true})

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
