call plug#begin('~/.local/share/nvim/plugged')
" design
Plug 'junegunn/goyo.vim'
" colorscheme
Plug 'sjl/badwolf'
Plug 'ayu-theme/ayu-vim'
" status
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Syntax & autocomplete
Plug 'Shougo/deoplete.nvim' , { 'do': ':UpdateRemotePlugins' }
Plug 'deoplete-plugins/deoplete-jedi' " jedi + deoplete
Plug 'davidhalter/jedi-vim'
Plug 'zchee/deoplete-jedi'
Plug 'tpope/vim-markdown'
" highlighting
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}
" ()'' autocomplete
Plug 'Raimondi/delimitMate'
Plug 'tpope/vim-surround'
" Indent lines
Plug 'Yggdroot/indentLine'
" Git
Plug 'airblade/vim-gitgutter'
" PEP8
Plug 'tell-k/vim-autopep8'
" Autoformatting
Plug 'sbdchd/neoformat'
call plug#end()

" semshi color change
function MyCustomHighlights()
    hi semshiAttribute      ctermfg=36 guifg=#00af87
    hi ColorColumn ctermbg=gray
endfunction
autocmd FileType python call MyCustomHighlights()
autocmd FileType python noremap <leader>ap :call Autopep8()<CR>

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
set clipboard=unnamed " use OS clipboard

" autopep8
let g:autopep8_max_line_length=79
let g:autopep8_indent_size=4
let g:autopep8_disable_show_diff=1
" let g:autopep8_aggressive=2

" autocomplete
let g:deoplete#enable_at_startup = 1
call deoplete#custom#option('num_processes', 1)

" autocomplete ()
let delimitMate_expand_cr=1

" Jump to the last position when reopening a file
if has("autocmd")
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" key bindings
" nore -> non recursive mapping
let mapleader = " "
nnoremap <C-l> :set background=light<CR>
nnoremap <C-s> :source ~/.init.vim<CR>
nnoremap <leader><Up> :resize +2<CR>
nnoremap <leader><Down> :resize -2<CR>
nnoremap <leader><Left> :vertical resize +2<CR>
nnoremap <leader><Right> :vertical resize -2<CR>
nnoremap <leader><ENTER> :Goyo<CR>
nnoremap <leader>,v :vsplit ~/.init.vim<CR>
nnoremap <leader>,s :split ~/.init.vim<CR>
nnoremap <leader>id :IndentLinesDisable<CR>
nnoremap <leader>ie :IndentLinesEnable<CR>
nnoremap <leader><leader> :Explore<CR>
nnoremap <leader>o :20Vexplore<CR>
nnoremap <leader>t :tabnew /home/mseok/<CR>
nnoremap <C-j> :tabprevious<CR>
nnoremap <C-k> :tabnext<CR>
nnoremap <C-n> :bn<CR>
nnoremap <C-p> :bn<CR>
nnoremap <C-x> :bd<CR>
nnoremap term :tab term<CR>
nnoremap <leader>gh :GitGutterPreviewHunk<CR>

" buffer control
nnoremap <C-n> :bn<CR>| " move to next buffer
nnoremap <C-p> :bp<CR>| " move to previous buffer
nnoremap <C-x> :bd<CR>| " delete current buffer

nnoremap <C-i> :w<CR>:!python %<CR>

colorscheme badwolf 
let g:spacegray_low_contrast = 1
let g:airline_theme='badwolf'
set background=dark
set t_Co=256
let ayucolor="light"  " for light version of theme
if has("gui_running") || g:colors_name=="ayu"
    set termguicolors
endif

function Light_ayu()
    set termguicolors
    set background=light
    let g:airline_theme='light'
    colorscheme ayu
endfunction
noremap <leader>light :call Light_ayu()<CR>

let g:airline#extensions#tabline#enabled = 1

hi! Normal ctermbg=NONE guibg=NONE
hi! NonText ctermbg=NONE guibg=NONE guifg=NONE ctermfg=NONE 

" Autoformatting
let g:neoformat_basic_format_align = 1  " Enable alignment
let g:neoformat_basic_format_retab = 1  " Enable tab to space conversion
let g:neoformat_basic_format_trim = 1  " Enable trimmming of trailing whitespace
noremap <leader>nf :Neoformat<CR>

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
