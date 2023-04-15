if exists("g:loaded_termnames")
	finish
endif
let g:loaded_termnames = 1

lua << EOF

vim.api.nvim_create_user_command("TermOpen", function(opts)
	require("termnames").create_terminal(opts.fargs)
end, { nargs = "*" })

vim.api.nvim_create_user_command("TermRename", function(opts)
	require("termnames").rename_terminal(opts.fargs)
end, { nargs = "+" })

vim.api.nvim_create_user_command("TermClose", function(opts)
	require("termnames").delete_terminal(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("TermRun", function(opts)
	require("termnames").run_terminal_cmd(opts.fargs)
end, { nargs = "+" })

vim.api.nvim_create_user_command("TermRefresh", function()
	require("termnames").update_term_bufnr()
end, { nargs = 0 })

vim.api.nvim_create_user_command("TermSave", function()
	require("termnames").save_terminal_data()
end, { nargs = 0 })

EOF
