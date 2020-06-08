call plug#begin('~/.local/share/nvim/plugged')
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'
Plug 'NLKNguyen/papercolor-theme'
" colorscheme
Plug 'morhetz/gruvbox'
Plug 'sjl/badwolf'
" status
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Syntax & autocomplete
Plug 'Shougo/deoplete.nvim' , { 'do': ':UpdateRemotePlugins' }
Plug 'davidhalter/jedi-vim' " python autocomplete
Plug 'tpope/vim-markdown'
" Plug 'deoplete-plugins/deoplete-jedi' " jedi + deoplete
Plug 'zchee/deoplete-jedi'
" highlighting
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}
" ()'' autocomplete
Plug 'Raimondi/delimitMate'
" Indent lines
Plug 'Yggdroot/indentLine'
call plug#end()

" semshi color change
function MyCustomHighlights()
    hi semshiAttribute      ctermfg=36 guifg=#00af87
endfunction
autocmd FileType python call MyCustomHighlights()

" basic vim setting
syntax on
set smartindent " indentation
set tabstop=4 " tab width 4
set shiftwidth=4 " >> << width 4
set expandtab " tab to space
set colorcolumn=80 " vertical line at 80
set laststatus=2 " shows uppder status line
set cmdheight=1 " command space height
set nobackup nowritebackup " no backups
set splitbelow splitright " opening vim at belowright position

" autocomplete
let g:deoplete#enable_at_startup = 1
call deoplete#custom#option('num_processes', 1)

" autocomplete ()
let delimitMate_expand_cr=1

" Uncomment the following to have Vim jump to the last position when reopening a file
if has("autocmd")
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" key bindings
" nore -> non recursive mapping
let mapleader = " "
" nnoremap <leader><Space> :CtrlP<CR>
nnoremap <C-l> :set background=light<CR>
" nnoremap <C-L> :set background=dark<CR>
nnoremap <C-s> :source ~/udg/mseok/.init.vim<CR>
" nnoremap <Up> :resize +2<CR>
" nnoremap <Down> :resize -2<CR>
nnoremap <Left> :vertical resize +2<CR>
nnoremap <Right> :vertical resize -2<CR>

nnoremap <leader><leader> :25Vexplore<CR>
nnoremap <leader><ENTER> :Goyo<CR>
nnoremap <leader>, :vsplit ~/udg/mseok/.init.vim<CR>
nnoremap <leader>id :IndentLinesDisable<CR>
nnoremap <leader>ie :IndentLinesEnable<CR>

" nnoremap <C-J> <C-W><C-J>
" nnoremap <C-K> <C-W><C-K>
" nnoremap <C-L> <C-W><C-L>
" nnoremap <C-H> <C-W><C-H>

" python commenting as vscode
autocmd FileType python nmap <C-_> <S-i># <Esc>
autocmd FileType python vmap <C-_> <S-i># <Esc>

map <F1> :colorscheme gruvbox<CR>
map <F2> :set background=dark<CR>:colorscheme badwolf<CR>
map <F3> :set background=light<CR>:colorscheme PaperColor<CR>

colorscheme badwolf 
let g:spacegray_low_contrast = 1
let g:airline_theme='badwolf'
set background=dark
set termguicolors
let g:airline#extensions#tabline#enabled = 1

hi! Normal ctermbg=NONE guibg=NONE
hi! NonText ctermbg=NONE guibg=NONE guifg=NONE ctermfg=NONE 

" Goyo
function! s:goyo_enter()
    set noshowmode
    set noshowcmd
    set scrolloff=999
    set number
    set rnu
    Limelight
    let g:limelight_conceal_guifg = 'DarkGray'
    let g:limelight_conceal_guifg = '#777777'
    let g:limelight_paragraph_span = 1
endfunction

function! s:goyo_leave()
    set showmode
    set showcmd
    set scrolloff=999
    Limelight!
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()
