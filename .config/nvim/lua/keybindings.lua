local api = vim.api
local cmd = vim.cmd
local g   = vim.g

local function map(mode, lhs, rhs, opts)
  local options = {noremap = true}
  if opts then options = vim.tbl_extend("force", options, opts) end
  api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Leader
g.mapleader = " "

map("n", "<C-s>", ":source $HOME/dot/.config/nvim/init.lua<CR>")
map("n", "<leader>,v", ":vsplit $HOME/dot/.config/nvim/init.lua<CR>")
map("n", "<leader>,s", ":split $HOME/dot/.config/nvim/init.lua<CR>")
map("n", "<leader><leader>", ":Explore<CR>")
map("n", "Y", "y$")
map("x", "K", ":move '<-2<CR>gv-gv")
map("x", "K", ":move '>+1<CR>gv-gv")

-- Buffer
map("n", "<C-n>", ":bn<CR>", {noremap = true})
map("n", "<C-p>", ":bp<CR>", {noremap = true})
map("n", "<leader>bd", ":bd<CR>", {noremap = true})

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

local scopes = {o = vim.o, b = vim.bo, w = vim.wo}
function opt(scope, key, value)
    scopes[scope][key] = value
    if scope ~= "o" then scopes["o"][key] = value end
end

local indent = 2
cmd "syntax enable"
cmd "filetype plugin indent on"
opt("b", "expandtab", true)
opt("b", "smartindent", true)
opt("b", "tabstop", indent)
opt("b", "shiftwidth", indent)
opt("o", "hidden", true)
opt("o", "splitbelow", true)
opt("o", "splitright", true)
opt("o", "clipboard","unnamed,unnamedplus")
opt("o", "laststatus", 2)
opt("o", "cmdheight", 2)

-- Autocmd
api.nvim_exec([[autocmd FileType python nnoremap <C-i> :w<CR>:!python %<CR>]], false)
-- api.nvim_exec([[autocmd FileType python set colorcolumn=80]], false)
api.nvim_exec([[autocmd FileType python set tabstop=4 shiftwidth=4]], false)

map("n", "<leader>cp", ":lua copy_mode()<CR>")
