local api = vim.api
local cmd = vim.cmd
local g = vim.g
local keymap = vim.keymap

-- Leader
g.mapleader = " "

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
