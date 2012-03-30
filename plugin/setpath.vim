" setpath.vim
"
" vim plugin for current path management related to 
" project root directory.
"
" Created November 15th 2011
" By Pascal Lalancette
"

set tags=./tags;

let s:projectFilesIndex = 0 " Index for projec files element in the list (project dict value)
let s:projectMakeProgIndex = 1 " Index for projec files element in the list (project dict value)
   
function! s:AddProject(projectPath, projectFiles, projectMakeProgram)
    if !has_key(g:projectDict, a:projectPath)
        "This is the first time this project is added to the dictionnary
        "Now is the good time to generate tags
        call s:CreateCtags(a:projectPath, a:projectFiles)
    endif
    " Save the project info in a global dict for future reference
    let g:projectDict[a:projectPath] = [a:projectFiles, a:projectMakeProgram]
endfunction

function! s:RemoveProject(projectPath)
    "TODO: implement me if you think it would be interesting to clean up
    "opened projects
endfunction

" Lookup the folder tree up to the root for a .vimproj file
" Once found, build a a list of files associated to this project
function! s:ResolveProject()
    if !exists("g:projectDict")
        " We make sure we have a dict 
        let g:projectDict = {}
    endif
    " Look up for a .vimproj file up to the root
    let vimProj = findfile(".vimproj", ".;")
    " If a a valid file, parse it
    if filereadable(vimProj)
        " Init the var we are looking to fill up
        let projectPath = fnamemodify(vimProj, ":h")
        let projectFiles = []
        let projectMakeProgram = ""
        " Read the .vimproj file one line at a time
        let items = readfile(vimProj)
        for n in items
            " Look for 'make_prog' tag
            let endIndex = matchend(n, '\c\s*\zsmake_prog\s*=')
            if endIndex != -1
                " Extract the name of the program 
                let projectMakeProgram = substitute(strpart(n, endIndex), "\\s*\\(\\S*\\)\\s*", "\\1", "")
                continue
            endif
            " Look for 'files' tag
            let endIndex = matchend(n, '\c\s*\zsfiles\s*=')
            if endIndex != -1
                let filePatternList = split(strpart(n, endIndex))
                for filePattern in filePatternList 
                    " Expand the pattern to get the full list of files
                    let projectFiles += split(globpath(projectPath."/", "**/".filePattern), "\n")
                endfor
                continue
            endif
        endfor
        " Add project to currently opened project list
        call s:AddProject(projectPath, projectFiles, projectMakeProgram)
        return projectPath
    endif
    return ""
endfunction

function! s:GetProjectFiles()
    if !exists("b:projectPath")
        " Save the project path in the buffer var
        let b:projectPath = s:ResolveProject()
    endif
    return g:projectDict[b:projectPath][s:projectFilesIndex]
endfunction

function! s:SetPath()
    if !exists("b:projectPath")
        return
    endif
    exe 'set path ='.b:projectPath."/**"
    let g:currentProjectPath = b:projectPath
endfunction

function! s:SetMakePrg()
    if !exists("b:projectPath")
        return
    endif
    exe 'setlocal makeprg='.g:projectDict[b:projectPath][s:projectMakeProgIndex]
endfunction

"" Ctags commands associated to language
"let ctagsCommand = {
"            \ 'CSharp'              : 'ctags -R --languages=c\# --c\#-kinds=+l *',
"            \ 'ObjectiveC'          : 'ctags -R *',
"            \ 'Python'              : 'ctags -R --languages=Python --Python-kinds=-i *',
"            \ 'Various'             : 'ctags -R *'
"            \ }

" This function create the ctags file in the path requested for 
" the list of files
" Note: the tags file is updated on buffer write by the plugin autotag.vim
function! s:CreateCtags(projectPath, files)
    echo "VimProj: Creating ctags for project path: ".a:projectPath
    let ctagsCmd = "ctags -R "
    let filesArgs = join(a:files, " ")
    let currentPath = getcwd()
    exe 'cd '.a:projectPath
    exe 'silent !'.ctagsCmd.filesArgs
    exe 'cd '.currentPath
endfunction

function! s:VimProjBufRead()
    call s:ResolveProject()
    call s:SetMakePrg()
endfunction

function! s:VimProjBufEnter()
    call s:SetPath()
endfunction

function! s:VimProjFuzzyFinder()
    if exists("*fuf#givenfile#launch")
        call fuf#givenfile#launch('', 0, '>', s:GetProjectFiles())
    endif
endfunction

augroup vimproj_bufenter
    au!
    au BufEnter * call s:VimProjBufEnter()
augroup END

augroup vimproj_bufread
    au!
    au BufNewFile,BufRead * call s:VimProjBufRead()
augroup END

com! VPFuzzyFinder       :call s:VimProjFuzzyFinder()
