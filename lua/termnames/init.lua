local Path = require("plenary.path")
local data_location = string.format("%s/termnames.json", vim.fn.stdpath("data"))

local M = {}

M.terminals = {}

-- Create terminal (CREATE)
function M.create_terminal(terminal_name)
	vim.cmd("terminal")
	local buf_name = vim.api.nvim_buf_get_name(0)
	M.terminals[buf_name] = terminal_name
end

-- Get data about terminals (READ)
function M.get_terminals()
	return M.terminals
end

function M.get_terminal_name(buf_name)
	return M.terminals[buf_name]
end

function M.get_current_terminal_name()
	local current_buf_name = vim.api.nvim_buf_get_name(0)
	return M.get_terminal_name(current_buf_name)
end

-- Rename terminal (UPDATE)
function M.rename_terminal(new_name)
	local buf_name = vim.api.nvim_buf_get_name(0)
	if M.terminals[buf_name] ~= nil then
		M.terminals[buf_name] = new_name
	else
		print("Current buffer is not a terminal")
	end
end

-- Delete terminal (DELETE)
function M.delete_terminal()
	local buf_name = vim.api.nvim_buf_get_name(0)
	if M.terminals[buf_name] ~= nil then
		M.terminals[buf_name] = nil
		vim.cmd("Bdelete!")
	else
		print("Current buffer is not a terminal")
	end
end

-- Save and restore terminal data

function M.save_terminal_data()
	local file = Path:new(data_location)
	local data = vim.json.decode(file:read())
	data[vim.fn.getcwd()] = M.terminals
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
		local cwd = vim.fn.getcwd()
		local cwd_data = data[cwd]
		if cwd_data ~= nil then
			M.terminals = cwd_data
		else
			M.terminals = {}
		end
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
		if M.terminals[current_buf_name] ~= nil then
			M.terminals[current_buf_name] = nil
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

-- M.find_buffer_by_name = function(name)
--   for _, buf in ipairs(vim.api.nvim_list_bufs()) do
--     local buf_name = vim.api.nvim_buf_get_name(buf)
--     if buf_name == name then
--       return buf
--     end
--   end
--   return -1
-- end
