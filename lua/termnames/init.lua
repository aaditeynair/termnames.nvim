local Path = require("plenary.path")
local data_location = string.format("%s/termnames.json", vim.fn.stdpath("data"))

local M = {}

TerminalData = TerminalData or {}

function GetCWDTermData()
	local cwd = vim.fn.getcwd()
	TerminalData[cwd] = TerminalData[cwd] or {}
	return TerminalData[cwd]
end

-- Create terminal (CREATE)
function M.create_terminal(terminal_name)
	vim.cmd("terminal")
	local buf_name = vim.api.nvim_buf_get_name(0)
	local term_data = GetCWDTermData()
	term_data[buf_name] = terminal_name
end

-- Get data about terminals (READ)
function M.get_terminals()
	return GetCWDTermData()
end

function M.get_terminal_name(buf_name)
	local term_data = GetCWDTermData()
	return term_data[buf_name]
end

function M.get_current_terminal_name()
	local current_buf_name = vim.api.nvim_buf_get_name(0)
	return M.get_terminal_name(current_buf_name)
end

function M.get_bufnr_of_terminal(term_name)
	local buffer_name = ""
	for buf_name, terminal_name in pairs(GetCWDTermData()) do
		if terminal_name == term_name then
			buffer_name = buf_name
		end
	end

	if not buffer_name then
		return nil
	end

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local buf_name = vim.api.nvim_buf_get_name(buf)
		if buf_name == buffer_name then
			return buf
		end
	end

	return nil
end

-- Rename terminal (UPDATE)
function M.rename_terminal(new_name)
	local buf_name = vim.api.nvim_buf_get_name(0)
	local term_data = GetCWDTermData()
	if term_data[buf_name] ~= nil then
		term_data[buf_name] = new_name
	else
		print("Current buffer is not a terminal")
	end
end

-- Delete terminal (DELETE)
function M.delete_terminal()
	local buf_name = vim.api.nvim_buf_get_name(0)
	local term_data = GetCWDTermData()
	if term_data[buf_name] ~= nil then
		term_data[buf_name] = nil
		vim.cmd("Bdelete!")
	else
		print("Current buffer is not a terminal")
	end
end

-- Save and restore terminal data

function M.save_terminal_data()
	local file = Path:new(data_location)
	local data = vim.json.decode(file:read())
	data[vim.fn.getcwd()] = GetCWDTermData()
	file:write(vim.json.encode(data), "w")
	file:close()
end

function M.restore_terminals()
	if not vim.fn.filereadable(data_location) then
		return
	end

	local file = Path:new(data_location)
	local data = vim.json.decode(file:read())
	if data ~= nil then
		TerminalData = data
	else
		TerminalData = {}
	end
	file:close()
end

-- Autocmds

local termnames_augroup = vim.api.nvim_create_augroup("TERMNAMES_NVIM", { clear = true })

vim.api.nvim_create_autocmd("BufUnload", {
	desc = "Delete terminal from terminal table",
	group = termnames_augroup,
	callback = function()
		local current_buf_name = vim.fn.expand("<afile>")
		local term_data = GetCWDTermData()
		if term_data[current_buf_name] ~= nil then
			term_data[current_buf_name] = nil
		end
	end,
})

vim.api.nvim_create_autocmd("ExitPre", {
	pattern = "*",
	callback = function()
		M.save_terminal_data()
	end,
})

M.restore_terminals()

return M
