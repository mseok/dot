-- Autoformatting
vim.g.neoformat_basic_format_align = 1
vim.g.neoformat_basic_format_retab = 1
vim.g.neoformat_basic_format_trim = 1
vim.g.neoformat_enabled_python = { "flake8", "autopep8", "black" }
vim.api.nvim_exec([[autocmd FileType python noremap <leader>nf :Neoformat black<CR>]], false)
