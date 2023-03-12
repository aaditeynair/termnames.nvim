if exists("g:loaded_termnames")
	finish
endif
let g:loaded_termnames = 1

command! -nargs=? TermOpen lua require("termnames").create_terminal(vim.fn.expand("<args>"))
command! -nargs=0 TermClose lua require("termnames").delete_terminal()
command! -nargs=0 TermTest lua require("termnames").restore_terminals()
command! -nargs=1 TermRename lua require("termnames").rename_terminal(vim.fn.expand("<args>"))
