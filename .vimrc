syntax on
set showcmd
set autoindent
set ruler
set number
set confirm
set shiftwidth=4
set tabstop=4
set mouse=a

set history=700

set autoread

set wildmenu

set cmdheight=2

set hlsearch

set magic

set mat=2

set ffs=unix,dos,mac
set encoding=utf8

set expandtab
set smarttab

set ai
set si
set wrap

set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l

function! HasPaste()
	if &paste
		return 'PASTE MODE '
	en
	return ''
endfunction

" Enhanced keyboard mappings
" https://gergap.wordpress.com/2009/05/29/minimal-vimrc-for-cc-developers/
" F2: save file (normal mode)
nmap <F2> :w<CR>
" F2: exit insert, save, enter insert (insert mode)
imap <F2> <ESC>:w<CR>i
" F4: switch between header and source
map <F4> :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>
" F7: build
map <F7> :make<CR>



colorscheme darkblue 
