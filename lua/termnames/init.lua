local Path = require("plenary.path")
local data_location = string.format("%s/termnames.json", vim.fn.stdpath("data"))

local M = {}

M.terminals = {}

-- Create terminal (CREATE)
function M.create_terminal(terminal_name)
	vim.cmd("terminal")
	local bufnr = tostring(vim.api.nvim_win_get_buf(0))
	M.terminals[bufnr] = terminal_name
end

-- Get data about terminals (READ)
function M.get_terminals()
	return M.terminals
end

function M.get_terminal_name(bufnr)
	if type(bufnr) ~= "string" then
		bufnr = tostring(bufnr)
	end
	return M.terminals[bufnr]
end

function M.get_current_terminal_name()
	local current_bufnr = tostring(vim.api.nvim_win_get_buf(0))
	return M.get_terminal_name(current_bufnr)
end

-- Rename terminal (UPDATE)
function M.rename_terminal(new_name)
	local bufnr = tostring(vim.api.nvim_win_get_buf(0))
	if M.terminals[bufnr] ~= nil then
		M.terminals[bufnr] = new_name
	else
		print("Current buffer is not a terminal")
	end
end

-- Delete terminal (DELETE)
function M.delete_terminal()
	local bufnr = tostring(vim.api.nvim_win_get_buf(0))
	if M.terminals[bufnr] ~= nil then
		M.terminals[bufnr] = nil
		vim.cmd("Bdelete!")
	else
		print("Current buffer is not a terminal")
	end
end

-- Save and restore terminal data

function M.save_terminal_data()
	local data = vim.fn.json_decode(vim.fn.readfile(data_location))
	data[vim.fn.getcwd()] = M.terminals
	Path:new(data_location):write(vim.fn.json_encode(data), "w")
end

function M.restore_terminals(data)
	if data == nil then
		M.terminals = {}
	else
		M.terminals = data
	end
end

-- Autocmds

local termnames_augroup = vim.api.nvim_create_augroup("TERMNAMES_NVIM", { clear = true })

vim.api.nvim_create_autocmd("BufUnload", {
	desc = "Delete terminal from terminal table",
	group = termnames_augroup,
	callback = function()
		local current_bufnr = vim.fn.expand("<abuf>")
		if M.terminals[current_bufnr] ~= nil then
			M.terminals[current_bufnr] = nil
		end
	end,
})

vim.api.nvim_create_autocmd("ExitPre", {
	pattern = "*",
	callback = function()
		M.save_terminal_data()
	end,
})

return M
