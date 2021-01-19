call plug#begin('~/.local/share/nvim/plugged')
" status
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'sjl/badwolf'
" Syntax & autocomplete
Plug 'Shougo/deoplete.nvim' , { 'do': ':UpdateRemotePlugins' }
Plug 'deoplete-plugins/deoplete-jedi' " jedi + deoplete
Plug 'davidhalter/jedi-vim'
Plug 'zchee/deoplete-jedi'
Plug 'tpope/vim-markdown'
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

" color
" hi Normal           ctermfg=0 ctermbg=231
" hi colorcolumn      ctermbg=255
" echo synIDattr(synID(line('.'), col('.'), 1), 'name')
autocmd FileType python nnoremap <C-i> :w<CR>:!python %<CR>
autocmd FileType python set colorcolumn=80 " vertical line at 80

" basic vim setting
syntax on
" set smartindent " indentation
set tabstop=2 " tab width
set shiftwidth=2 " >> << width
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

" autocomplete
let g:deoplete#enable_at_startup = 1
call deoplete#custom#option('num_processes', 1)
let g:jedi#completions_enabled = 0

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

" Tab
nnoremap term :tab term<CR>
nnoremap <C-j> :tabprevious<CR>
nnoremap <C-k> :tabnext<CR>
nnoremap <leader>t :tabnew $INSTALL_DIR<CR>

" git
nnoremap <leader>gh :GitGutterPreviewHunk<CR>

" buffer control
nnoremap <C-n> :bn<CR>| " move to next buffer
nnoremap <C-p> :bp<CR>| " move to previous buffer
nnoremap <C-x> :bd<CR>| " delete current buffer


" colorscheme functions
function Dark_colorscheme()
    " colorscheme goodwolf
    colorscheme badwolf
    let g:airline_theme='simple'
endfunction
function Light_colorscheme()
    colorscheme mgoodwolf
    let g:airline_theme='sol'
endfunction
noremap <leader>dark :call Dark_colorscheme()<CR>
noremap <leader>light :call Light_colorscheme()<CR>
" call Light_colorscheme()
call Dark_colorscheme()
hi Comment ctermbg=None
hi Normal  ctermbg=None

" Autoformatting
let g:neoformat_basic_format_align = 1  " Enable alignment
let g:neoformat_basic_format_retab = 1  " Enable tab to space conversion
let g:neoformat_basic_format_trim = 1  " Enable trimmming of trailing whitespace
autocmd FileType python noremap <leader>nf :Neoformat<CR>

nnoremap <leader>id :IndentLinesDisable<CR>
nnoremap <leader>ie :IndentLinesEnable<CR>
