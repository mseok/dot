call plug#begin('~/.local/share/nvim/plugged')
" design
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'sjl/badwolf'
Plug 'kristijanhusak/vim-hybrid-material'
Plug 'jaxbot/semantic-highlight.vim'
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}
" Syntax & autocomplete
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'deoplete-plugins/deoplete-jedi'
Plug 'davidhalter/jedi-vim'
" ()'' autocomplete
Plug 'Raimondi/delimitMate'
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
set cmdheight=2 " command space height
set nobackup nowritebackup " no backups
set splitbelow splitright " opening vim at belowright position
set path+=**
set clipboard=unnamed " use OS clipboard
set completeopt-=preview " deoplete complete do not show window

hi! StatusLineNC ctermbg=None guibg=None
hi! VertSplit ctermbg=None guibg=None
set fillchars+=vert:\|  " vertical line character

" Autocomplete (Deoplete, Jedi)
let g:deoplete#enable_at_startup = 1
let g:jedi#completions_enabled = 0
let g:jedi#show_call_signatures = 2
let g:jedi#goto_command = "<C-f>"
function Jedi_call_signature_colors()
    hi! jediFat ctermbg=None ctermfg=red guifg=#ff0000 guibg=None term=bold,underline cterm=bold,underline gui=bold,underline
endfunction
autocmd FileType python call Jedi_call_signature_colors()

" highlighting
let g:semshi#mark_selected_nodes = 0
let g:semshi#excluded_hl_groups = ['local', ]
let g:semshi#error_sign = 0
let g:semshi#mark_selected_nodes = 0
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

" autocomplete ()
let delimitMate_expand_cr = 1

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
    let g:airline_theme='hybrid'
    colorscheme hybrid_material
    hi Normal ctermbg=None guibg=None
endfunction
function Light_colorscheme()
    " colorscheme mgoodwolf
    set termguicolors
    set background=light
    let g:airline_theme='silver'
    colorscheme vim-material
endfunction
noremap <leader>dark :call Dark_colorscheme()<CR>
noremap <leader>light :call Light_colorscheme()<CR>
" call Light_colorscheme()
call Dark_colorscheme()

" Autoformatting
let g:neoformat_basic_format_align = 1  " Enable alignment
let g:neoformat_basic_format_retab = 1  " Enable tab to space conversion
let g:neoformat_basic_format_trim = 1  " Enable trimmming of trailing whitespace
autocmd FileType python noremap <leader>nf :Neoformat<CR>

function Copy_mode()
    execute "IndentLinesDisable"
    execute "GitGutterDisable"
endfunction
function Normal_mode()
    execute "IndentLinesEnable"
    execute "GitGutterEnable"
endfunction

nnoremap <leader>cp :call Copy_mode()<CR>
nnoremap <leader>nc :call Normal_mode()<CR>
