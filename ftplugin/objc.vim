
function! SetFoldMode()
    "Set the fold based on syntax
    if getbufvar(1, "&foldmethod") != "syntax"
        "echo "Setting foldmethod to syntax for objective-c source code"
        setlocal foldmethod=syntax
    endif
endfunction

au BufEnter *.m call SetFoldMode()
