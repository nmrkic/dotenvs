syntax on
filetype indent plugin on
" colorscheme pencil
:augroup numbertoggle
:  autocmd!
:  autocmd BufEnter,FocusGained,InsertLeave * set nu relativenumber
:  autocmd BufLeave,FocusLost,InsertEnter   * set nonu norelativenumber
:augroup END
" sistemski clipboard: unnamed = macOS / Linux PRIMARY, unnamedplus = Linux Ctrl+V
set clipboard=unnamed,unnamedplus
