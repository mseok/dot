call plug#begin('~/mseok/.local/share/nvim/plugged')
" Prettier
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'sjl/badwolf'
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}
Plug 'frazrepo/vim-rainbow'
" Syntax & autocomplete
Plug 'hrsh7th/nvim-compe'
Plug 'neovim/nvim-lspconfig'
" Indent Lines
Plug 'Yggdroot/indentLine'
" Git
Plug 'airblade/vim-gitgutter'
" Autoformatting
Plug 'sbdchd/neoformat'
Plug 'nvie/vim-flake8'
" Start Page
Plug 'mhinz/vim-startify'
call plug#end()

filetype plugin on

autocmd FileType python nnoremap <C-i> :w<CR>:!python %<CR>
autocmd FileType python set colorcolumn=80

" basic vim setting
syntax on
set expandtab smartindent
set tabstop=4 shiftwidth=4
set laststatus=2
set nobackup nowritebackup
set splitbelow splitright
set path+=**
set clipboard=unnamed
set completeopt=menuone,noselect
set cmdheight=2

" Autocomplete
let $AUTOCOMPLETE = $HOME.'/dot/.config/nvim/autocomplete.vim'
if filereadable($AUTOCOMPLETE)
  source $AUTOCOMPLETE
endif

" Autoformatting
let g:neoformat_basic_format_align=1  " Enable alignment
let g:neoformat_basic_format_retab=1  " Enable tab to space conversion
let g:neoformat_basic_format_trim=1   " Enable trimmming of trailing whitespace
let g:neoformat_enabled_python = ["flake8", "autopep8", "black"]
autocmd FileType python noremap <leader>nf :Neoformat autopep8<CR>
autocmd FileType python noremap <leader>f :call flake8#Flake8()<CR>

" Themes
hi! StatusLineNC ctermbg=None guibg=None
hi! VertSplit ctermbg=None guibg=None
set fillchars+=vert:\|
" Airline
let g:airline#extensions#tabline#enabled=1
" Highlighting
let g:semshi#mark_selected_nodes=0
let g:semshi#excluded_hl_groups=['local', ]
let g:semshi#error_sign=0
let g:semshi#mark_selected_nodes=0
function MyCustomHighlights()
    hi semshiLocal           ctermfg=209 guifg=#ff875f
    hi semshiGlobal          ctermfg=214 guifg=#ffaf00
    hi semshiImported        ctermfg=214 guifg=#ffaf00 cterm=bold gui=bold
    hi semshiParameter       ctermfg=75  guifg=#5fafff
    hi semshiParameterUnused ctermfg=117 guifg=#87d7ff cterm=underline gui=underline
    hi semshiFree            ctermfg=218 guifg=#ffafd7
    hi semshiBuiltin         ctermfg=207 guifg=#ff5fff
    hi semshiAttribute       ctermfg=36  guifg=#00af87
    hi semshiSelf            ctermfg=249 guifg=#b2b2b2
    hi semshiUnresolved      ctermfg=226 guifg=#ffff00 cterm=underline gui=underline
endfunction
autocmd ColorScheme * call MyCustomHighlights()
let g:rainbow_active=1
let g:rainbow_guifgs = ['RoyalBlue3', 'DarkOrange3', 'DarkOrchid3', 'FireBrick']
let g:rainbow_ctermfgs = ['lightblue', 'lightgreen', 'yellow', 'red', 'magenta']

" Jump to the last position when reopening a file
if has("autocmd")
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" colorscheme functions
function Dark_colorscheme()
    set background=dark
    set termguicolors
    let g:airline_theme='hybrid'
    colorscheme badwolf
    call MyCustomHighlights()
endfunction
function Light_colorscheme()
    set termguicolors
    set background=light
    let g:airline_theme='silver'
    let g:tokyonight_style = "day"
    colorscheme tokyonight
    call MyCustomHighlights()
endfunction
nnoremap <leader>dark :call Dark_colorscheme()<CR>
nnoremap <leader>light :call Light_colorscheme()<CR>
" call Light_colorscheme()
call Dark_colorscheme()

function Copy_mode()
    execute "IndentLinesDisable"
    execute "GitGutterDisable"
endfunction
function Normal_mode()
    execute "IndentLinesEnable"
    execute "GitGutterEnable"
endfunction

" key bindings
let mapleader = " "
nnoremap <C-s> :source $HOME/dot/.config/nvim/init.vim<CR>
nnoremap <leader>,v :vsplit $HOME/dot/.config/nvim/init.vim<CR>
nnoremap <leader>,s :split $HOME/dot/.config/nvim/init.vim<CR>
nnoremap <leader><leader> :Explore<CR>
nnoremap Q <nop>
xnoremap K :move '<-2<CR>gv-gv
xnoremap J :move '>+1<CR>gv-gv
" Buffer
nnoremap <C-n> :bn<CR>
nnoremap <C-p> :bn<CR>
nnoremap <C-x> :bd<CR>
" git
nnoremap <leader>gh :GitGutterPreviewHunk<CR>
nnoremap <leader>cp :call Copy_mode()<CR>
nnoremap <leader>nc :call Normal_mode()<CR>
