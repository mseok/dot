call plug#begin('~/.local/share/nvim/plugged')
" design
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'sjl/badwolf'
Plug 'hzchirs/vim-material'
Plug 'mhinz/vim-startify'
Plug 'vim-python/python-syntax'
" Syntax & autocomplete
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'deoplete-plugins/deoplete-jedi'
" ()'' autocomplete
Plug 'Raimondi/delimitMate'
Plug 'tpope/vim-surround'
" Indent lines
Plug 'Yggdroot/indentLine'
" Git
Plug 'airblade/vim-gitgutter'
" Autoformatting
Plug 'sbdchd/neoformat'
call plug#end()

autocmd FileType python nnoremap <C-i> :w<CR>:!python %<CR>
autocmd FileType python set colorcolumn=80 " vertical line at 80

" basic vim setting
syntax on
" set smartindent " indentation
set tabstop=4 " tab width
set shiftwidth=4 " >> << width
set expandtab " tab to space
set laststatus=2 " shows uppder status line
set cmdheight=1 " command space height
set nobackup nowritebackup " no backups
set splitbelow splitright " opening vim at belowright position
set path+=**
set clipboard=unnamed " use OS clipboard

hi! StatusLineNC ctermbg=None guibg=None
hi! VertSplit ctermbg=None guibg=None
set fillchars+=vert:\|  " vertical line character

" python-syntax
let g:python_highlight_all = 1

" deoplete
let g:deoplete#enable_at_startup = 1
let g:jedi#completions_enabled = 1

" autocomplete ()
let delimitMate_expand_cr=1

" Jump to the last position when reopening a file
if has("autocmd")
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" airline
let g:airline#extensions#tabline#enabled = 1

" key bindings
let mapleader = " "
nnoremap <C-s> :source $INSTALL_DIR/.init.vim<CR>
nnoremap <leader>,v :vsplit $INSTALL_DIR/.init.vim<CR>
nnoremap <leader>,s :split $INSTALL_DIR/.init.vim<CR>
nnoremap <leader><leader> :Explore<CR>

" Buffer
nnoremap <C-n> :bn<CR>
nnoremap <C-p> :bn<CR>
nnoremap <C-x> :bd<CR>

" Tags
nnoremap <C-f> <C-]>

" git
nnoremap <leader>gh :GitGutterPreviewHunk<CR>

" buffer control
nnoremap <C-n> :bn<CR>| " move to next buffer
nnoremap <C-p> :bp<CR>| " move to previous buffer
nnoremap <C-x> :bd<CR>| " delete current buffer

" colorscheme functions
function Dark_colorscheme()
    set background=dark
    set termguicolors
    " colorscheme badwolf
    colorscheme vim-material
    let g:airline_theme='material'
endfunction
function Light_colorscheme()
    " colorscheme mgoodwolf
    set termguicolors
    set background=light
    colorscheme vim-material
    let g:airline_theme='material'
endfunction
noremap <leader>dark :call Dark_colorscheme()<CR>
noremap <leader>light :call Light_colorscheme()<CR>
call Light_colorscheme()
" call Dark_colorscheme()

" Autoformatting
let g:neoformat_basic_format_align = 1  " Enable alignment
let g:neoformat_basic_format_retab = 1  " Enable tab to space conversion
let g:neoformat_basic_format_trim = 1  " Enable trimmming of trailing whitespace
autocmd FileType python noremap <leader>nf :Neoformat<CR>

nnoremap <leader>id :IndentLinesDisable<CR>
nnoremap <leader>ie :IndentLinesEnable<CR>
