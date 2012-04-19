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
let s:VIMPROJ_TAG_MAKEPRG = 'makeprg'
let s:VIMPROJ_TAG_CTAGS_ARGS = 'ctags_args'
let s:VIMPROJ_TAG_FILES = 'files'
let s:VIMPROJ_COMMENT = '"'

" projectDict constants
let s:PROJECT_CTAGS_ARGS = 0 
let s:PROJECT_MAKEPRG = 1
let s:PROJECT_FILES = 2


function! s:AddProject(projectPath, projectCtagsArgs, projectMakePrg, projectFiles)
    if !exists("g:projectDict")
        " We make sure we have a dict 
        let g:projectDict = {}
    endif
    if !has_key(g:projectDict, a:projectPath)
        "This is the first time this project is added to the dictionnary
        "Now is the good time to generate tags
        call s:CreateCtags(a:projectPath, a:projectCtagsArgs, a:projectFiles)
    endif
    " Save the project info in a global dict for future reference
    let g:projectDict[a:projectPath] = [a:projectCtagsArgs, a:projectMakePrg, a:projectFiles]
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

function! s:GetProjectFiles()
    return g:projectDict[b:projectPath][s:PROJECT_FILES]
endfunction

" Lookup the folder tree up to the root for a .vimproj file
" Once found, build a a list of files associated to this project
function! ResolveProject()
    " Look up for a .vimproj file up to the root
    let vimProj = findfile(".vimproj", ".;")
    " If a a valid file, parse it
    if filereadable(vimProj)
        " Init the var we are looking to fill up
        let projectPath = fnamemodify(vimProj, ":p:h")
        let projectCtagsArgs = []
        let projectFiles = []
        let projectMakePrg = ""
        " Read the .vimproj file one line at a time
        let items = readfile(vimProj)
        for n in items
            " Look for commented line
            let endIndex = matchend(n, '\c\s*\zs'.s:VIMPROJ_COMMENT.'.*')
            if endIndex != -1
                " Skip this line
                continue
            endif
            " Look for 'makeprg' tag
            let endIndex = matchend(n, '\c\s*\zs'.s:VIMPROJ_TAG_MAKEPRG.'\s*=')
            if endIndex != -1
                " Extract the name of the program 
                let projectMakePrg = substitute(strpart(n, endIndex), "\\s*\\(\\.*\\)\\s*", "\\1", "")
                continue
            endif
            " Look for 'ctags_args' tag
            let endIndex = matchend(n, '\c\s*\zs'.s:VIMPROJ_TAG_CTAGS_ARGS.'\s*=')
            if endIndex != -1
                let projectCtagsArgs = split(strpart(n, endIndex))
                continue
            endif
            " Look for 'files' tag
            let endIndex = matchend(n, '\c\s*\zs'.s:VIMPROJ_TAG_FILES.'\s*=')
            if endIndex != -1
                "let projectFiles = split(strpart(n, endIndex))
                let projectFiles = s:ResolveFiles(projectPath, split(strpart(n,endIndex)))
                continue
            endif
        endfor
        " Add project to currently opened project list
        call s:AddProject(projectPath, projectCtagsArgs, projectMakePrg, projectFiles)
    endif
endfunction

nmap <silent> ,t :w\|so%\|call ResolveProject()<CR>

function! s:ResolveFiles(projectPath, filesPatternList)
    let l:resolvedFiles = []
    for filePattern in a:filesPatternList
        let l:pattern = '*'
        let l:folder = ''
        let filePattern = substitute(filePattern, '^[\|/]\(.*\)$', '\1', "")

        if match(filePattern, '/') >= 0
            let l:folder = substitute(filePattern, '\(.*/\).*$', '\1', "")
        else
            let l:folder = ''
        endif

        let pattern = substitute(filePattern, '.*/\(.*\)$', '\1', "")

        if match(pattern, '*') != -1 && folder != ''
            " this is a star search in a folder
            let pattern = '**/'.pattern
        endif

        exe 'cd '.a:projectPath
        let l:resolvedFiles += split(globpath(a:projectPath, folder.pattern), "\n")

        let l:relativeFiles = []
        for absoluteFile in l:resolvedFiles
            let l:relativeFiles += [fnamemodify(absoluteFile, ":.")]
        endfor
    endfor
    return l:relativeFiles
endfunction

function! s:SetPath()
    if !s:ProjectExist()
        return
    endif
    " TODO: Force the current working directory to be at the root of the project. This is to be
    " compatible with FuzzyFinder plugin (it is a bug the dev are aware
    " of). Once this bug is fixed in FuzzyFinder, it wont be required to inforce the current 
    " working directory to be the project root.
    "exe 'cd '.s:GetProjectPath()
    exe 'set path ='.s:GetProjectPath()."/**"
endfunction

function! s:SetMakePrg()
    if !s:ProjectExist()
        return
    endif
    exe 'setlocal makeprg='.s:GetProjectMakeProg()
endfunction

" This function create the tags file (ctags) in the project path
function! s:CreateCtags(projectPath, args, projectFiles)
    let ctagsCmd = "ctags ".join(a:args, " ")." ".join(a:projectFiles, " ")
    exe 'cd '.a:projectPath
    exe 'silent !'.ctagsCmd
endfunction

function! s:VimProjBufRead()
    exe 'cd %:p:h'
    echomsg "VimProjBufRead called"
    call ResolveProject()
    call s:SetMakePrg()
endfunction

function! s:VimProjBufEnter()
    exe 'cd %:p:h'
    call s:SetPath()
endfunction

function! s:VimProjFuzzyFindFiles()
    if !s:ProjectExist()
        return
    endif
    let filesList = s:GetProjectFiles()
    echo filesList
    exe 'cd '.s:GetProjectPath()
    call fuf#givenfile#launch('', 0, '>', filesList)
endfunction

augroup vimproj_bufenter
    au!
    au BufEnter *.vim,*.py,*.h,*.m,*.mm call s:VimProjBufEnter()
augroup END

augroup vimproj_bufread
    au!
    au BufNewFile,BufRead *.vim,*.py,*.h,*.m,*.mm call s:VimProjBufRead()
augroup END

" Command Mappings
if !exists(":VimProjFuzzyFindFiles")
    command VimProjFuzzyFindFiles :call <SID>VimProjFuzzyFindFiles()
endif
