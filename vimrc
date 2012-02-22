"-----------------------------------------------------------------------------
" Cream Gvim stuff
"-----------------------------------------------------------------------------
set nocompatible

"-----------------------------------------------------------------------------
" Global Stuff
"-----------------------------------------------------------------------------

" Get pathogen up and running
filetype off 
call pathogen#infect()
call pathogen#helptags()

" Set the HOME 
if has('win32') || has ('win64')
    let $HOME = $VIM."/vimfiles"
    "let $HOME = $VIM."d:"
else
    let $VIMHOME = $HOME."/.vim"
endif

" Set filetype stuff to on
filetype on
filetype plugin on
filetype indent on

" Tabstops are 4 spaces
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

" Printing options
set printoptions=header:0,duplex:long,paper:letter

" set the search scan to wrap lines
set wrapscan

" I'm happy to type the case of things.  I tried the ignorecase, smartcase
" thing but it just wasn't working out for me
"set noignorecase
set ignorecase "Plalancette: trying the ignore case

" Make command line two lines high
set ch=2

" set visual bell -- i hate that damned beeping
set vb

" Allow backspacing over indent, eol, and the start of an insert
set backspace=2

" Make sure that unsaved buffers that are to be put in the background are 
" allowed to go in there (ie. the "must save first" error doesn't come up)
set hidden

" Set the status line
set stl=%f\ %m\ Line:%l/%L[%p%%]\ Col:%v\ Buf:#%n\ [%b][0x%B]

" tell VIM to always put a status line in, even if there is only one window
set laststatus=2

" Don't update the display while executing macros
set lazyredraw

" Don't show the current command int he lower right corner.  In OSX, if this is
" set and lazyredraw is set then it's slow as molasses, so we unset this
set showcmd

" Show the current mode
set showmode

" Switch on syntax highlighting.
syntax on

" Hide the mouse pointer while typing
set mousehide

" Set up the gui cursor to look nice
set guicursor=n-v-c:block-Cursor-blinkon0,ve:ver35-Cursor,o:hor50-Cursor,i-ci:ver25-Cursor,r-cr:hor20-Cursor,sm:block-Cursor-blinkwait175-blinkoff150-blinkon175

" This is the timeout used while waiting for user input on a multi-keyed macro
" or while just sitting and waiting for another key to be pressed measured
" in milliseconds.
"
" i.e. for the ",d" command, there is a "timeoutlen" wait period between the
"      "," key and the "d" key.  If the "d" key isn't pressed before the
"      timeout expires, one of two things happens: The "," command is executed
"      if there is one (which there isn't) or the command aborts.
"set timeoutlen=500

" Keep some stuff in the history
set history=100

" These commands open folds
"set foldopen=block,insert,jump,mark,percent,quickfix,search,tag,undo

" When the page starts to scroll, keep the cursor 8 lines from the top and 8
" lines from the bottom
set scrolloff=8

" Make the command-line completion better
set wildmenu

" ignore files
set wildignore=*.o,*.obj,*.exe,*.hi,*.tmp,*~,*.pyc,*.swp

" Enable search highlighting
set hlsearch

" Incrementally match the search
set incsearch

" Automatically read a file that has changed on disk
set autoread

" Make sure the line are displayed
set number

" System default for mappings is now the "," character
let mapleader = ","

" Turn off that stupid highlight search
nmap <silent> ,n :nohls<CR>

" Show all available VIM servers
nmap <silent> ,ss :echo serverlist()<CR>

" Maps to make handling windows a bit easier
noremap <silent> ,h :wincmd h<CR>
noremap <silent> ,j :wincmd j<CR>
noremap <silent> ,k :wincmd k<CR>
noremap <silent> ,l :wincmd l<CR>
noremap <silent> ,sb :wincmd p<CR>
noremap <silent> ,cj :wincmd j<CR>:close<CR>
noremap <silent> ,ck :wincmd k<CR>:close<CR>
noremap <silent> ,ch :wincmd h<CR>:close<CR>
noremap <silent> ,cl :wincmd l<CR>:close<CR>
noremap <silent> ,cc :close<CR>
noremap <silent> ,cw :cclose<CR>
noremap <silent> ,ml <C-W>L
noremap <silent> ,mk <C-W>K
noremap <silent> ,mh <C-W>H
noremap <silent> ,mj <C-W>J

" Edit the vimrc file
nmap <silent> ,ev :e $MYVIMRC<CR>
nmap <silent> ,sv :so $MYVIMRC<CR>

" Search the current file for what's currently in the search register and display matches
nmap <silent> ,gs :vimgrep /<C-r>// %<CR>:ccl<CR>:cwin<CR><C-W>J:nohls<CR>

" Search the current file for the word under the cursor and display matches
nmap <silent> ,gw :vimgrep /<C-r><C-w>/ %<CR>:ccl<CR>:cwin<CR><C-W>J:nohls<CR>

" Search the current file for the WORD under the cursor and display matches
nmap <silent> ,gW :vimgrep /<C-r><C-a>/ %<CR>:ccl<CR>:cwin<CR><C-W>J:nohls<CR>

" Toggle fullscreen mode
if has('win32') || has ('win64')
	nmap <silent> <F3> :call libcallnr("gvimfullscreen.dll", "ToggleFullScreen", 0)<CR>
endif

" Alright... let's try this out
imap jj <esc>

" Syntax coloring lines that are too long just slows down the world
set synmaxcol=2048

" I don't like it when the matching parens are automatically highlighted
let loaded_matchparen = 1

"-----------------------------------------------------------------------------
" Set up fonts
"-----------------------------------------------------------------------------
if has("mac")
  let g:main_font = "Anonymous\\ Pro:h14"
  let g:small_font = "Anonymous\\ Pro:h2"
else
  let g:main_font = "Anonymous\\ Pro:h13"
  let g:small_font = "Anonymous\\ Pro:h2"
endif

"-----------------------------------------------------------------------------
" Set up the window colors and size
"-----------------------------------------------------------------------------
if has("gui_running")
  exe "set guifont=" . g:main_font
  set background=dark
  colorscheme wombat
  if !exists("g:vimrcloaded")
      winpos 0 0
      if !&diff
          winsize 130 120
      else
          winsize 227 120
      endif
      let g:vimrcloaded = 1
  endif
endif
:nohls

" When entering a buffer, change the current working directory
autocmd BufEnter * cd %:p:h

" disable toolbar
set guioptions-=T

" Perforce
let s:IgnoreChange=0
autocmd! FileChangedRO * nested
    \ let s:IgnoreChange=1 |
    \ call system("p4 edit " . expand("%")) |
    \ set noreadonly
autocmd! FileChangedShell *
    \ if 1 == s:IgnoreChange |
    \   let v:fcs_choice="" |
    \   let s:IgnoreChange=0 |
    \ else |
    \   let v:fcs_choice="ask" |
    \ endif


" Directory. Ignore these files
let g:netrw_list_hide= '.*\.swp$,.*\.pyc$'

" Select the color scheme
::colorscheme wombat

" Configure the tags file search rule. 
set tags=./tags;

" Pydoc script location
let g:pydoc_cmd = "python pydoc"

"-----------------------------------------------------------------------------
" Clang_complete
"-----------------------------------------------------------------------------

" Blocks are not enabled by default in clang. Cocoa frameworks use them
" extensively.
let g:clang_user_options='-fblocks'

" Complete options (disable preview scratch window)
set completeopt=menu,menuone,longest
 
" Limit popup menu height
set pumheight=15
 
" SuperTab option for context aware completion
let g:SuperTabDefaultCompletionType = "context"

" Disable auto popup, use <Tab> to autocomplete
let g:clang_complete_auto = 0

" Show clang errors in the quickfix window
let g:clang_complete_copen = 1

" The quotes at the beggining of clang_exec and at the end of clang_user_options are important, don't remove them
" They basically trick vim into thinking clang executed fine, because the msvc build autocompletes correctly but fails
" to compile.
" Don't forget to put paths with spaces in quotes other wise vim won't be able to execute the command
if has('win32') || has ('win64')
let g:clang_exec = '"C:\clang\clang.exe'
let g:clang_user_options = '2> NUL || exit 0"'
endif

"-----------------------------------------------------------------------------
" SuperTab plugin
"-----------------------------------------------------------------------------

" Disable supertab in text file. Was annoying!
autocmd BufEnter *.txt let b:SuperTabDisabled=1

"-----------------------------------------------------------------------------
" FuzzyFinder plugin
"-----------------------------------------------------------------------------
nnoremap <silent> ,f :FufFile<CR>

"-----------------------------------------------------------------------------
" FSwitch plugin
"-----------------------------------------------------------------------------
nnoremap <silent> ,a :FSHere<CR>

