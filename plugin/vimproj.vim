" vimproj.vim
"
" vim plugin to manage folder associations and 
" makeprg (to run or compile a project)
"
" Created November 15th 2011
" By Pascal Lalancette
"

set tags=./tags;

" .vimproj file tags
let s:VIMPROJ_FILE_TAG_MAKEPRG = 'makeprg'
let s:VIMPROJ_FILE_TAG_CTAGS_ARGS = 'ctags_args'

" projectDict constants
let s:PROJECT_CTAGS_ARGS = 0 
let s:PROJECT_MAKEPRG = 1

   
function! s:AddProject(projectPath, projectCtagsArgs, projectMakePrg)
    if !exists("g:projectDict")
        " We make sure we have a dict 
        let g:projectDict = {}
    endif
    if !has_key(g:projectDict, a:projectPath)
        "This is the first time this project is added to the dictionnary
        "Now is the good time to generate tags
        call s:CreateCtags(a:projectPath, a:projectCtagsArgs)
    endif
    " Save the project info in a global dict for future reference
    let g:projectDict[a:projectPath] = [a:projectCtagsArgs, a:projectMakePrg]
    " Mark the current buffer
    let b:projectPath = a:projectPath
endfunction

function! s:RemoveProject(projectPath)
    "TODO: implement me if you think it would be interesting to clean up
    "opened projects
endfunction

function! s:ProjectExist()
    return exists("b:projectPath")
endfunction

function! s:GetProjectPath()
    return b:projectPath
endfunction

function! s:GetProjectMakeProg()
    return g:projectDict[b:projectPath][s:PROJECT_MAKEPRG]
endfunction

function! s:GetProjectCtagsArgs()
    return g:projectDict[b:projectPath][s:PROJECT_CTAGS_ARGS]
endfunction

" Lookup the folder tree up to the root for a .vimproj file
" Once found, build a a list of files associated to this project
function! s:ResolveProject()
    " Look up for a .vimproj file up to the root
    let vimProj = findfile(".vimproj", ".;")
    " If a a valid file, parse it
    if filereadable(vimProj)
        " Init the var we are looking to fill up
        let projectPath = fnamemodify(vimProj, ":p:h")
        let projectCtagsArgs = []
        let projectMakePrg = ""
        " Read the .vimproj file one line at a time
        let items = readfile(vimProj)
        for n in items
            " Look for 'makeprg' tag
            let endIndex = matchend(n, '\c\s*\zs'.s:VIMPROJ_FILE_TAG_MAKEPRG.'\s*=')
            if endIndex != -1
                " Extract the name of the program 
                let projectMakePrg = substitute(strpart(n, endIndex), "\\s*\\(\\.*\\)\\s*", "\\1", "")
                continue
            endif
            " Look for 'ctags_args' tag
            let endIndex = matchend(n, '\c\s*\zs'.s:VIMPROJ_FILE_TAG_CTAGS_ARGS.'\s*=')
            if endIndex != -1
                let projectCtagsArgs = split(strpart(n, endIndex))
                continue
            endif
        endfor
        " Add project to currently opened project list
        call s:AddProject(projectPath, projectCtagsArgs, projectMakePrg)
    endif
endfunction

function! s:SetPath()
    if !s:ProjectExist()
        return
    endif
    " TODO: Force the current working directory to be at the root of the project. This is to be
    " compatible with FuzzyFinder plugin (it is a bug the dev are aware
    " of). Once this bug is fixed in FuzzyFinder, it wont be required to inforce the current 
    " working directory to be the project root.
    exe 'cd '.s:GetProjectPath()
    exe 'set path ='.s:GetProjectPath()."/**"
endfunction

function! s:SetMakePrg()
    if !s:ProjectExist()
        return
    endif
    exe 'setlocal makeprg='.s:GetProjectMakeProg()
endfunction

" This function create the tags file (ctags) in the project path
function! s:CreateCtags(projectPath, args)
    let ctagsCmd = "ctags ".join(a:args, " ")
    exe 'cd '.a:projectPath
    exe 'silent !'.ctagsCmd
endfunction

function! VimProjBufRead()
    exe 'cd %:p:h'
    call s:ResolveProject()
    call s:SetMakePrg()
endfunction

function! VimProjBufEnter()
    exe 'cd %:p:h'
    call s:SetPath()
endfunction

augroup vimproj_bufenter
    au!
    au BufEnter *.py,*.cs,*.cpp,*.h,*.m,*.mm call VimProjBufEnter()
augroup END

augroup vimproj_bufread
    au!
    au BufNewFile,BufRead *.py,*.cs,*.cpp,*.h,*.m,*.mm call VimProjBufRead()
augroup END
