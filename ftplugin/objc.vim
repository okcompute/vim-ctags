
function! SetFoldMode()
    "Set the fold based on syntax
    if getbufvar(1, "&foldmethod") != "syntax"
        "echo "Setting foldmethod to syntax for objective-c source code"
        setlocal foldmethod=syntax
    else
        echo "foldmethod in objective-c is already fine"
    endif
endfunction

au BufEnter *.m call SetFoldMode()
