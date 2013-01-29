" Vim-Ctags.vim
"
" Version 1.0
"
" Automatic generation of tags file (Exhuberant Ctags)
"
" Description: This script look for .ctags file in the current
" directory hiearchy up to the root and build the tags file 
" when one is found. This process is executed only for the 
" first file opened in the whole directory tree. 
"
" Notes: 
" - Combine this plugin and the AutoTags plugin and you won't
" need to think about generating tags anymore.
" - For further details on the .ctags file, see Exhuberant Ctags
"   documentations.
"
" Requirement: Exhuberant Ctags must be installed on your system.
" 
" Created November 15th 2011
" By Pascal Lalancette
"

set tags=./tags;

let g:vimctags_debug = 0

function! s:ShowDebugMsg(msg)
    if g:vimctags_debug != 0
        echomsg "Vim-Ctags :".a:msg
    endif
endfunction

function! s:IsBufferHasTags()
    return exists("b:ctagsPath")
endfunction

function! s:GetBufferCtagsPath()
    return b:ctagsPath
endfunction

function! s:IsCtagsGenerated(ctagsPath)
    if !exists("g:ctagsDict")
        return 0
    endif
    return has_key(g:ctagsDict, a:ctagsPath)
endfunction

function! s:SaveGenerationStatus(ctagsPath)
    if !exists("g:ctagsDict")
        " Make sure the project dict is initialized
        let g:ctagsDict = {}
        echomsg "Vim-Ctags : Generated tags file from Ctags file \'".a:ctagsPath."\.ctags'"
    endif

    " Save a key in a global dict. 
    let g:ctagsDict[a:ctagsPath] = "ctags generated"
endfunction

" Lookup the folder tree up to the root for a .ctags file
" Once found, generates tags file if not done already
function! ResolveCtagsFile()
    call s:ShowDebugMsg("Resolving ctags config file (.ctags)")
    " Look up for a .ctags file up to the root
    let ctags = findfile(".ctags", ".;")
    " If a a valid file, parse it
    if !filereadable(ctags)
        call s:ShowDebugMsg(".ctags file not found")
        return
    endif
    call s:ShowDebugMsg("Found a ctags file: ".ctags)

    " Extract the project path from the .ctags filename
    let ctagsPath = fnamemodify(ctags, ":p:h")

    if !s:IsCtagsGenerated(ctagsPath)
        call s:GenerateTags(ctagsPath)
    endif

    " Save the ctags location path to current buffer local var
    let b:ctagsPath = ctagsPath

    call s:ShowDebugMsg("Ctags path for buffer: ".ctagsPath)
endfunction

" This function create the tags file (ctags) 
function! s:GenerateTags(ctagsPath)
    call s:ShowDebugMsg("Creating ctags file")
    " Create a ctags shell command 
    let ctagsCmd = "ctags -R ."
    exe 'cd '.a:ctagsPath
    exe 'silent !'.ctagsCmd
   
    " Save the generation result
    call s:SaveGenerationStatus(a:ctagsPath)
endfunction

function! s:VimCtagsBufRead()
    " Save the current directory. Will return to it after
    let currentDirectory = getcwd()
    " Change current directory to the buffer one
    exe 'cd %:p:h'
    call ResolveCtagsFile()
    " Back to original directory
    exe 'cd '.currentDirectory
endfunction

augroup vimctags_bufread
    au!
    au BufNewFile,BufRead *.vim,*.py,*.h,*.m,*.mm call s:VimCtagsBufRead()
augroup END
