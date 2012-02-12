
function! SetFoldMode()
    "Set the fold based on syntax
    if getbufvar(1, "&foldmethod") != "indent"
        echo "Setting foldmethod to indent for python script"
        setlocal foldmethod=indent
        "setlocal foldlevelstart=0
    else
        echo "Foldmethod in python script is already fine"
    endif
endfunction

au BufEnter *.py call SetFoldMode()
