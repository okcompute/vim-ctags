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

" .vimproj file keys
let s:VIMPROJ_KEY_MAKEPRG = 'makeprg'
let s:VIMPROJ_KEY_CTAGS_ARGS = 'ctags_args'
let s:VIMPROJ_KEY_FILES = 'files'
let s:VIMPROJ_COMMENTS_LINE = '"'

" vimprojDict index constants
let s:PROJECT_CTAGS_ARGS_INDEX = 0 
let s:PROJECT_MAKEPRG_INDEX = 1
let s:PROJECT_FILES_INDEX = 2


function! s:AddProject(projectPath, projectCtagsArgs, projectMakePrg, projectFiles)
    if !exists("g:vimprojDict")
        " Make sure the project dict is initialized
        let g:vimprojDict = {}
        echo "VimProj: Project \'".a:projectPath."\' added (".len(a:projectFiles)." files)"
    endif
    if !has_key(g:vimprojDict, a:projectPath)
        "This is the first time this project is added to the dictionnary.
        "Now is the good time to generate tags. 
        "Note: Auto updates of tags are not handled by vimproj.
        "Suggestion: Install the Autotags.vim plugin. 
        call s:CreateCtags(a:projectPath, a:projectCtagsArgs, a:projectFiles)
    endif
    " Save the project info in a global dict shared by all buffers
    let g:vimprojDict[a:projectPath] = [a:projectCtagsArgs, a:projectMakePrg, a:projectFiles]
    " Mark the project path to current buffer
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
    return g:vimprojDict[b:projectPath][s:PROJECT_MAKEPRG_INDEX]
endfunction

function! s:GetProjectCtagsArgs()
    return g:vimprojDict[b:projectPath][s:PROJECT_CTAGS_ARGS_INDEX]
endfunction

function! s:GetProjectFiles()
    return g:vimprojDict[b:projectPath][s:PROJECT_FILES_INDEX]
endfunction

" Lookup the folder tree up to the root for a .vimproj file
" Once found, build a a list of files associated to this project
function! ResolveProject()
    " Look up for a .vimproj file up to the root
    let vimProj = findfile(".vimproj", ".;")
    " If a a valid file, parse it
    if !filereadable(vimProj)
        return
    endif

    " Init the var we are looking to fill up
    let projectPath = fnamemodify(vimProj, ":p:h")
    let projectCtagsArgs = []
    let projectFiles = []
    let projectMakePrg = ""

    " Read the .vimproj file one line at a time
    let items = readfile(vimProj)
    for n in items
        " Look for commented line
        let endIndex = matchend(n, '\c\s*\zs'.s:VIMPROJ_COMMENTS_LINE.'.*')
        if endIndex != -1
            " Skip this line
            continue
        endif
        " Look for 'makeprg' tag
        let endIndex = matchend(n, '\c\s*\zs'.s:VIMPROJ_KEY_MAKEPRG.'\s*=')
        if endIndex != -1
            " Extract the name of the program 
            let projectMakePrg = substitute(strpart(n, endIndex), "\\s*\\(\\.*\\)\\s*", "\\1", "")
            continue
        endif
        " Look for 'ctags_args' tag
        let endIndex = matchend(n, '\c\s*\zs'.s:VIMPROJ_KEY_CTAGS_ARGS.'\s*=')
        if endIndex != -1
            let projectCtagsArgs = split(strpart(n, endIndex))
            continue
        endif
        " Look for 'files' tag
        let endIndex = matchend(n, '\c\s*\zs'.s:VIMPROJ_KEY_FILES.'\s*=')
        if endIndex != -1
            let projectFiles = s:ResolveFiles(projectPath, split(strpart(n,endIndex)))
            continue
        endif
    endfor
    " Add project to currently opened project list
    call s:AddProject(projectPath, projectCtagsArgs, projectMakePrg, projectFiles)

endfunction

function! s:ResolveFiles(projectPath, filesPatternList)
    let l:resolvedFiles = []
    for filePattern in a:filesPatternList
        let l:pattern = '*'
        let l:folder = ''
        let filePattern = substitute(filePattern, '^[\|/]\(.*\)$', '\1', "")

        " Lookup for the folder part in the pattern
        if match(filePattern, '[\|/]') >= 0
            let l:folder = substitute(filePattern, '\(.*/\).*$', '\1', "")
        endif

        " extract the pattern
        let l:pattern = fnamemodify(filePattern, ':t')

        if match(pattern, '*') != -1 && folder != ''
            " This is a star search in a folder. Force recursion
            let pattern = '**/'.pattern
        endif

        " Make sure the current working directory is the project path
        exe 'cd '.a:projectPath

        let l:resolvedFiles += split(globpath(a:projectPath, folder.pattern), "\n")

        " Convert all the files in a relative mode. i.e. make it prettier for 
        " the user.
        let l:relativeFiles = []
        for absoluteFile in l:resolvedFiles
            if has('win32') || has ('win64')
                let index = match(absoluteFile, '\.')
                let l:relativeFiles += [strpart(absoluteFile, index)]
            else
                let l:relativeFiles += [fnamemodify(absoluteFile, ":.")]
            endif
        endfor
    endfor
    return l:relativeFiles
endfunction

function! s:SetPath()
    if !s:ProjectExist()
        return
    endif
    exe 'set path ='.escape(s:GetProjectPath(), ' \')."/**"
endfunction

function! s:SetMakePrg()
    if !s:ProjectExist()
        return
    endif
    exe 'setlocal makeprg='.s:GetProjectMakeProg()
endfunction

" This function create the tags file (ctags) in the project path
function! s:CreateCtags(projectPath, args, projectFiles)
    let tmpfile = tempname()
    if writefile(a:projectFiles, tmpfile) != 0
        echoerr "VimProj Error: Cannot write to temporary file. Aborting Ctags generation!"
        return
    endif
    " Create a ctags shell command that receive the project files from a temp file
    let ctagsCmd = "ctags ".join(a:args, " ").' -L '.tmpfile
    exe 'cd '.a:projectPath
    exe 'silent !'.ctagsCmd
    if delete(tmpfile) != 0
        echoerr "VimProj Error: Cannot delete temporary file: ".tmpfile
    endif
endfunction

function! s:VimProjBufRead()
    exe 'cd %:p:h'
    call ResolveProject()
    call s:SetMakePrg()
endfunction

function! s:VimProjBufEnter()
    exe 'cd %:p:h'
    call s:SetPath()
endfunction

function! s:VimProjFuzzyFindFiles()
    " A project must have been set for this buffer
    if !s:ProjectExist()
        return
    endif
    " Collaboration between vimproj and FuzzyFinder Plugin
    " FuzzyFinder must be installed
    if !exists("*fuf#givenfile#launch")
        return
    endif
    let filesList = s:GetProjectFiles()
    exe 'cd '.s:GetProjectPath()
    call fuf#givenfile#launch('', 0, '>', filesList)
endfunction

function! s:VimProjReset()
    if s:ProjectExist()
        " Erase any traces of vimproj
        unlet g:vimprojDict
        unlet b:projectPath
    endif
    " ReInit the project on current buffer
    call s:VimProjBufRead()
endfunction

function! s:VimProjAddFile()
endfunction

function! s:VimProjDeleteFile()
endfunction

function! s:VimProjGrep(command)
    let currentDirectory = getcwd()
    exe 'cd '.s:GetProjectPath()
    " call vimgrep with autocommand disabled on all project files. We disable
    " autocommands otherwise the process is really slow.
    execute "noautocmd vimgrep".a:command." ".join(VimProjGetFiles(), " ")
    " Automatically open the quickfix window (author privilege :-))
    execute "copen"
    exe 'cd '.currentDirectory
endfunction

function! s:VimProjSubstitute(command)
    " TODO: impelement this so it is more user friendly. It should
    " loop on the file one by one:
    " 1)get to know if a buffer exist. 
    " 2) execute the substitute command
    " 3) if the buffer was already opened => next
    " 4) if the buffer was not already opened and is modified => next
    " 5) if the buffer is not modified, delete it and goto next
    " it exist, never delete the buffer
    let currentDirectory = getcwd()
    exe 'cd '.s:GetProjectPath()
    " Set this window to use a local arglist
    exe 'arglocal'
    "build up the arg list
    exe 'argadd '.join(VimProjGetFiles(), " ")
    "call substitute on every file 
    execute "noautocmd argdo %s".a:command
    " flush the arg list
    exe 'argd *'
    exe 'cd '.currentDirectory
endfunction

function! VimProjGetFiles()
    return s:GetProjectFiles()
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
" ================

if !exists(":VimProjFuzzyFindFiles")
    command VimProjFuzzyFindFiles :call <SID>VimProjFuzzyFindFiles()
endif

if !exists(":VimProjReset")
    command VimProjReset :call <SID>VimProjReset()
endif

if !exists(":VimProjAddFile")
    command VimProjAddFile :call <SID>VimProjAddFile()
endif

if !exists(":VimProjDeleteFile")
    command VimProjDeleteFile :call <SID>VimProjDeleteFile()
endif

if !exists(":VimProjGrep")
    command -nargs=1 -complete=command VimProjGrep call <SID>VimProjGrep(<q-args>)
endif

" VimProjGrep abbreviation for faster input. Bonus: no uppercase like user
" defined command
cnoreabbrev vpg VimProjGrep

if !exists(":VimProjSubstitute")
    command -nargs=1 -complete=command VimProjSubstitute call <SID>VimProjSubstitute(<q-args>)
endif

" VimProjSubstitute abbreviation for faster input. Bonus: no uppercase like user
" defined command
cnoreabbrev vps VimProjSubstitute
