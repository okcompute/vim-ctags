" setpath.vim
"
" vim plugin for current path management related to 
" project root directory.
"
" Created November 15th 2011
" By Pascal Lalancette
"

" Create a list of projectPath project


"\ ['D:/perforce_pop/assassin/ac/dev/tools/ExternalPackagesAddons/config/Source', 'Python', 'DeployEpa.py'],
"\ ['D:/perforce_pop/assassin/ac/dev/tools/ExternalPackagesAddons/config/Launcher', 'Python', 'MobuLauncher.pyw'],
"\ ['D:/perforce_pop/assassin/ac/dev/tools/ExternalPackagesAddons/packages/MotionBuilder/2010/Common/Scripts', 'Python', ''],
"\ ['D:/perforce_pop/assassin/ac/dev/tools/ExternalPackagesAddons/common/python', 'Python', '']

let projectList = [
\ ['~/Developer/Git/VirtualLifeDrawing', 'CSharp', '']
\ ]
   
" Ctags commands associated to language
let ctagsCommand = {
            \ 'CSharp'              : 'ctags -R --languages=c\# --c\#-kinds=+l *',
            \ 'ObjectiveC'          : 'C:\cygwin\bin\ctags -R *',
            \ "Python"              : 'C:\cygwin\bin\ctags -R --languages=Python --Python-kinds=-i *'
            \ }

" This fucntion take the current file directory
" And set the path to the parent project root path
function! SetPathAccordingToProject()
    let sourcePath = expand('%:p:h')
    let sourcePath = substitute(sourcePath, "\\", "\/", "g")
    let projectFound = 0

    " Loop through all project to find it
    for [projectPath, languages, main] in g:projectList
        let projectPath = substitute(projectPath, "\\", "\/", "g")
        let rootPath = matchstr(sourcePath, projectPath)
        if rootPath != ""
            exe 'set path ='.projectPath."/**"
            let projectFound = 1
            break
        endif
    endfor

    " Look if the current sourcePath contains the projectPath
    if projectFound == 0
        set path=D:/Downloads
    endif
endfunction


function! SetMakePrgAccordingToProject()
    let sourcePath = expand('%:p:h')
    let sourcePath = substitute(sourcePath, "\\", "\/", "g")

    " Loop through all project to find it
    for [projectPath, languages, main] in g:projectList
        let rootPath = matchstr(sourcePath, projectPath)
        if rootPath != ""
            exe 'setlocal makeprg=python\ '.projectPath.'/'.main
            break
        endif
    endfor
endfunction


" This function update the tags file for all the project listed
function! UpdateCtags()
    " Loop through all project to find it
    for [projectPath, languages, main] in g:projectList
        let ctagsCmd = g:ctagsCommand[languages]
        "exe '!cd '.projectPath.';'.ctagsCmd
        exe 'cd '.projectPath
        exe 'silent !'.ctagsCmd
        echomsg "Updating Ctags" .projectPath . ctagsCmd
    endfor
endfunction


augroup path_set
    au!
    au BufEnter *.cpp call SetPathAccordingToProject()
    au BufEnter *.py call SetPathAccordingToProject()
    au BufEnter *.cs call SetPathAccordingToProject()
    au BufEnter *.m call SetPathAccordingToProject()
    au BufEnter *.mm call SetPathAccordingToProject()
    au BufEnter *.h call SetPathAccordingToProject()
augroup END

augroup make_set
    au!
    au BufRead *.py,*.pyw call SetMakePrgAccordingToProject()
augroup END


" Update tags when starting vim
call UpdateCtags()

set tags=./tags;

set path=D:\perforce_pop\assassin\ac\dev\tools\ExternalPackagesAddons
