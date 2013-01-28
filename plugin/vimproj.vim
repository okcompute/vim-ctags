" Vimproj.vim
"
" Version 0.9
"
" Manage files associations, ctags arguments and 
" makeprg (to run or compile a project) for a group of files.
"
" TODO: - Update the project when a file is created or deleted
"
" Created November 15th 2011
" By Pascal Lalancette
"

set tags=./tags;

let g:vimproj_debug = 0

function! s:ShowDebugMsg(msg)
    if g:vimproj_debug != 0
        echomsg "Vimproj :".a:msg
    endif
endfunction

function! s:IsBufferHasTags()
    return exists("b:ctagsPath")
endfunction

function! s:GetBufferCtagsPath()
    return b:ctagsPath
endfunction

function! s:IsCtagsGenerated(ctagsPath)
    if !exists("g:vimprojDict")
        return 0
    endif
    return has_key(g:vimprojDict, a:ctagsPath)
endfunction

function! s:SaveGenerationStatus(ctagsPath)
    if !exists("g:vimprojDict")
        " Make sure the project dict is initialized
        let g:vimprojDict = {}
        echomsg "VimProj : Ctags file \'".a:ctagsPath."\' added"
    endif

    " Save a key in a global dict. 
    let g:vimprojDict[a:ctagsPath] = "ctags generated"
endfunction

" Lookup the folder tree up to the root for a .vimproj file
" Once found, build a a list of files associated to this project
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

    " Extract the project path from the vimProj filename
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

function! s:VimProjBufRead()
    exe 'cd %:p:h'
    call ResolveCtagsFile()
endfunction

augroup vimproj_bufread
    au!
    au BufNewFile,BufRead *.vim,*.py,*.h,*.m,*.mm call s:VimProjBufRead()
augroup END
