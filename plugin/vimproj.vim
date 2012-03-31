" vimproj.vim
"
" vim plugin to manage folder associations and 
" makeprg (to run or compile a project)
"
" Created November 15th 2011
" By Pascal Lalancette
"

set tags=./tags;

let s:PROJECTFOLDER = 0 
let s:PROJECTMAKEPRG = 1
   
function! s:AddProject(projectPath, projectFolders, projectMakePrg)
    if !exists("g:projectDict")
        " We make sure we have a dict 
        let g:projectDict = {}
    endif
    if !has_key(g:projectDict, a:projectPath)
        "This is the first time this project is added to the dictionnary
        "Now is the good time to generate tags
        call s:CreateCtags(a:projectPath, a:projectFolders)
    endif
    " Save the project info in a global dict for future reference
    let g:projectDict[a:projectPath] = [a:projectFolders, a:projectMakePrg]
    " Mark the current buffer
    let b:projectPath = a:projectPath
endfunction

function! s:RemoveProject(projectPath)
    "TODO: implement me if you think it would be interesting to clean up
    "opened projects
endfunction

function! s:IsProjectExisting()
    return exists("b:projectPath")
endfunction

function! s:GetProjectPath()
    return b:projectPath
endfunction

function! s:GetProjectMakeProg()
    return g:projectDict[b:projectPath][s:PROJECTMAKEPRG]
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
        let projectFolders = []
        let projectMakePrg = ""
        " Read the .vimproj file one line at a time
        let items = readfile(vimProj)
        for n in items
            " Look for 'make_prog' tag
            let endIndex = matchend(n, '\c\s*\zsmake_prog\s*=')
            if endIndex != -1
                " Extract the name of the program 
                let projectMakePrg = substitute(strpart(n, endIndex), "\\s*\\(\\.*\\)\\s*", "\\1", "")
                continue
            endif
            " Look for 'folder' tag
            let endIndex = matchend(n, '\c\s*\zsfolders\s*=')
            if endIndex != -1
                let projectFolders = split(strpart(n, endIndex))
                continue
            endif
        endfor
        " Add project to currently opened project list
        call s:AddProject(projectPath, projectFolders, projectMakePrg)
    endif
endfunction

function! s:SetPath()
    if !s:IsProjectExisting()
        return
    endif
    exe 'cd '.s:GetProjectPath()
    exe 'set path ='.s:GetProjectPath()."/**"
endfunction

function! s:SetMakePrg()
    if !s:IsProjectExisting()
        return
    endif
    exe 'setlocal makeprg='.s:GetProjectMakeProg()
endfunction

" This function create the tags file (ctags) in the project path
function! s:CreateCtags(projectPath, folders)
    let ctagsCmd = "ctags "
    let foldersArgs = join(a:folders, " ")
    exe 'cd '.a:projectPath
    exe 'silent !'.ctagsCmd.foldersArgs
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
