-- Autocmd
api.nvim_exec([[autocmd FileType python nnoremap <C-i> :w<CR>:!python %<CR>]], false)
api.nvim_exec([[autocmd FileType python set tabstop=4 shiftwidth=4]], false)
api.nvim_exec([[autocmd User Startified setlocal cursorline]], false)

