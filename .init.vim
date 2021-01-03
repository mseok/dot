call plug#begin('~/.local/share/nvim/plugged')
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
" Autoformatting
Plug 'sbdchd/neoformat'
call plug#end()

" semshi color change
function MyCustomHighlights()
    hi semshiAttribute       ctermfg=36 guifg=#00af87
    hi semshiLocal           ctermfg=209 guifg=#ff875f
    hi semshiGlobal          ctermfg=214 guifg=#ffaf00
    hi semshiImported        ctermfg=214 guifg=#ffaf00 cterm=bold gui=bold
    hi semshiParameter       ctermfg=75  guifg=#5fafff
    hi semshiParameterUnused ctermfg=117 guifg=#87d7ff cterm=underline gui=underline
    hi semshiFree            ctermfg=218 guifg=#ffafd7
    hi semshiBuiltin         ctermfg=207 guifg=#ff5fff
    hi semshiSelf            ctermfg=249 guifg=#b2b2b2
    hi semshiUnresolved      ctermfg=80 guifg=#5fd7d7 cterm=underline gui=underline
    hi semshiSelected        ctermfg=231 guifg=#ffffff ctermbg=161 guibg=#d7005f
    hi semshiErrorSign       ctermfg=231 guifg=#ffffff ctermbg=160 guibg=#d70000
    hi semshiErrorChar       ctermfg=231 guifg=#ffffff ctermbg=160 guibg=#d70000
endfunction
autocmd ColorScheme * call MyCustomHighlights()
autocmd FileType python call MyCustomHighlights()
autocmd FileType python nnoremap <C-i> :w<CR>:!python %<CR>
autocmd FileType python set colorcolumn=80 " vertical line at 80

" basic vim setting
syntax on
set smartindent " indentation
set tabstop=4 " tab width 4
set shiftwidth=4 " >> << width 4
set expandtab " tab to space
set laststatus=2 " shows uppder status line
set cmdheight=1 " command space height
set nobackup nowritebackup " no backups
set splitbelow splitright " opening vim at belowright position
set langmap=ㅎg,ㅓj,ㅏk,ㅣl,ㅗh " key mapping from kr to en
set path+=**
set clipboard=unnamed " use OS clipboard

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

" key bindings
let mapleader = " "
nnoremap <C-l> :set background=light<CR>
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
    colorscheme badwolf 
    let g:airline_theme='badwolf'
    set background=dark
    set t_Co=256
    set termguicolors
    hi! ColorColumn ctermbg=252 guibg=#d0d0d0
endfunction
function Light_colorscheme()
    colorscheme ayu
    let g:airline_theme='light'
    let g:ayucolor="light"  " for light version of theme
    set background=light
    set t_Co=256
    set termguicolors
    hi! Normal ctermbg=255 guibg=#EEEEEE
    hi! Visual ctermfg=255 guifg=#EEEEEE ctermbg=237 guibg=#3A3A3A
    hi! ColorColumn ctermbg=252 guibg=#d0d0d0
endfunction
noremap <leader>dark :call Dark_colorscheme()<CR>
noremap <leader>light :call Light_colorscheme()<CR>

" time dependent colorscheme setting
function CheckTime()
    let hr=(strftime('%H'))
    if hr >= 19
        call Dark_colorscheme()
    elseif hr >= 8
        call Light_colorscheme()
    elseif hr >= 0
        call Dark_colorscheme()
    endif
endfunction
autocmd FileType * call CheckTime()

hi! Normal ctermbg=NONE guibg=NONE
hi! NonText ctermbg=NONE guibg=NONE guifg=NONE ctermfg=NONE 

" Autoformatting
let g:neoformat_basic_format_align = 1  " Enable alignment
let g:neoformat_basic_format_retab = 1  " Enable tab to space conversion
let g:neoformat_basic_format_trim = 1  " Enable trimmming of trailing whitespace
autocmd FileType python noremap <leader>nf :Neoformat<CR>

nnoremap <leader>id :IndentLinesDisable<CR>
nnoremap <leader>ie :IndentLinesEnable<CR>
