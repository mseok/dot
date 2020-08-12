call plug#begin('~/.local/share/nvim/plugged')
" design
Plug 'junegunn/goyo.vim'
Plug 'NLKNguyen/papercolor-theme'
" colorscheme
Plug 'sjl/badwolf'
Plug 'ayu-theme/ayu-vim'
" status
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Syntax & autocomplete
Plug 'Shougo/deoplete.nvim' , { 'do': ':UpdateRemotePlugins' }
Plug 'deoplete-plugins/deoplete-jedi' " jedi + deoplete
" Plug 'davidhalter/jedi-vim'
Plug 'zchee/deoplete-jedi'
Plug 'tpope/vim-markdown'
" highlighting
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}
" ()'' autocomplete
Plug 'Raimondi/delimitMate'
" Indent lines
Plug 'Yggdroot/indentLine'

Plug 'tpope/vim-surround'
Plug 'airblade/vim-gitgutter'
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
set langmap=ㅎg,ㅓj,ㅏk,ㅣl,ㅗh " key mapping from kr to en
set path+=**

let g:netrw_liststyle=3

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
nnoremap <leader><Up> :resize +2<CR>
nnoremap <leader><Down> :resize -2<CR>
nnoremap <leader><Left> :vertical resize +2<CR>
nnoremap <leader><Right> :vertical resize -2<CR>

nnoremap <leader><ENTER> :Goyo<CR>
nnoremap <leader>, :vsplit ~/udg/mseok/.init.vim<CR>
nnoremap <leader>id :IndentLinesDisable<CR>
nnoremap <leader>ie :IndentLinesEnable<CR>
nnoremap <leader><leader> :Explore<CR>
nnoremap <leader>t :tabnew /home/wykgroup/udg/mseok<CR>
nnoremap <C-j> :tabprevious<CR>
nnoremap <C-k> :tabnext<CR>
nnoremap <C-n> :bn<CR>
nnoremap <C-p> :bn<CR>
nnoremap <C-x> :bd<CR>
nnoremap term :tab term<CR>

nnoremap <leader>gh :GitGutterPreviewHunk<CR>

" buffer control
" move to next buffer
" move to previous buffer
" delete current buffer
nnoremap <C-n> :bn<CR> 
nnoremap <C-p> :bp<CR> 
nnoremap <C-x> :bd<CR> 

" python commenting as vscode
autocmd FileType python nmap <C-_> <S-i># <Esc>
autocmd FileType python vmap <C-_> <S-i># <Esc>

colorscheme badwolf 
let g:spacegray_low_contrast = 1
let g:airline_theme='badwolf'
set background=dark
set t_Co=256
" let ayucolor="light"  " for light version of theme                                                                                             
" let ayucolor="mirage" " for mirage version of theme                                                                                            
" let ayucolor="dark"   " for dark version of theme                                                                                              
" colorscheme ayu
if has("gui_running") || g:colors_name=="ayu"                                                                                                    
    set termguicolors
endif

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
endfunction

function! s:goyo_leave()
    set showmode
    set showcmd
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()
