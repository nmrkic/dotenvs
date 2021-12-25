syntax on
filetype indent plugin on
" colorscheme pencil
:augroup numbertoggle
:  autocmd!
:  autocmd BufEnter,FocusGained,InsertLeave * set nu relativenumber
:  autocmd BufLeave,FocusLost,InsertEnter   * set nonu norelativenumber
:augroup END
set clipboard+=unnamed
call plug#begin('~/.vim/plugged')
Plug 'fagih/vim-go', { 'do': ':GoUpdateBinaries' } 
call plug#end()

