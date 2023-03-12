if exists("g:loaded_termnames")
	finish
endif
let g:loaded_termnames = 1

lua << EOF

vim.api.nvim_create_user_command("TermOpen", function(opts)
	require("termnames").create_terminal(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("TermRename", function(opts)
	require("termnames").rename_terminal(opts.fargs)
end, { nargs = "+" })

vim.api.nvim_create_user_command("TermClose", function(opts)
	require("termnames").delete_terminal(opts.args)
end, { nargs = "?" })

EOF
