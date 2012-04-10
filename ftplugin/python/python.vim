
function! SetFoldMode()
    "Set the fold based on syntax
    if getbufvar(1, "&foldmethod") != "indent"
        setlocal foldmethod=indent
    endif
endfunction

au BufEnter *.py call SetFoldMode()

" comment (cb) or uncomment (ub) block (require vim-indent plugin)
nmap <leader>cb vii \| :s!^!#! \| :noh<CR>
nmap <leader>ub vii \| :s!^#!! \| :noh<CR>

