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
	local term_data = GetCWDTermData()
	local id = 1
	if term_data[1] then
		id = term_data[#term_data].id + 1
	end
	local new_term = {
		["name"] = terminal_name,
		["bufnr"] = vim.api.nvim_win_get_buf(0),
		["id"] = id,
	}
	table.insert(term_data, new_term)
end

-- Get data about terminals (READ)
function M.get_terminals()
	return GetCWDTermData()
end

function M.get_terminal_name(bufnr)
	local term_data = GetCWDTermData()
	for _, term in ipairs(term_data) do
		if term.bufnr == bufnr then
			return term
		end
	end
end

function M.get_current_terminal_name()
	local current_bufnr = vim.api.nvim_win_get_buf(0)
	return M.get_terminal_name(current_bufnr)
end

-- Rename terminal (UPDATE)
function M.rename_terminal(new_name)
	local bufnr = vim.api.nvim_win_get_buf(0)
	local term_data = GetCWDTermData()
	for _, term in ipairs(term_data) do
		if term.bufnr == bufnr then
			term.name = new_name
		else
			print("Current buffer is not a terminal")
		end
	end
end

-- Delete terminal (DELETE)
function M.delete_terminal()
	local bufnr = vim.api.nvim_win_get_buf(0)
	local term_data = GetCWDTermData()
	local index = nil
	for i, term in ipairs(term_data) do
		if term.bufnr == bufnr then
			index = i
			vim.cmd("Bdelete!")
			break
		end
	end
	if index then
		term_data[index] = nil
	else
		print("Current buffer is not in the terminal list")
	end
end

-- Save and restore terminal data

function M.save_terminal_data()
	local file = Path:new(data_location)
	local data = vim.json.decode(file:read())
	local terminal_data = GetCWDTermData()

	data[vim.fn.getcwd()] = terminal_data
	file:write(vim.json.encode(data), "w")
	file:close()

	for _, term in ipairs(terminal_data) do
		if vim.fn.bufexists(term.bufnr) then
			vim.api.nvim_buf_delete(term.bufnr, { force = true })
		end
	end
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

function M.update_term_bufnr()
	local term_data = GetCWDTermData()
	local used_bufnr = {}

	local function has_value(tab, val)
		for _, value in ipairs(tab) do
			if value == val then
				return true
			end
		end

		return false
	end

	for _, terminal in ipairs(term_data) do
		local bufnr = terminal.bufnr
		if has_value(vim.api.nvim_list_bufs(), bufnr) then
			if vim.api.nvim_buf_get_name(bufnr):find("^term://") ~= nil then
				if has_value(used_bufnr, bufnr) then
					CreateNewTermForBuf(terminal)
				else
					terminal.bufnr = bufnr
					table.insert(used_bufnr, bufnr)
				end
			else
				CreateNewTermForBuf(terminal)
			end
		else
			CreateNewTermForBuf(terminal)
		end
	end
end

function CreateNewTermForBuf(terminal)
	local original_bufnr = vim.api.nvim_win_get_buf(0)
	vim.cmd("terminal")
	local new_bufnr = vim.api.nvim_win_get_buf(0)
	terminal.bufnr = new_bufnr
	vim.api.nvim_win_set_buf(0, original_bufnr)
end

-- Autocmds

local termnames_augroup = vim.api.nvim_create_augroup("TERMNAMES_NVIM", { clear = true })

vim.api.nvim_create_autocmd("BufUnload", {
	desc = "Delete terminal from terminal table",
	group = termnames_augroup,
	callback = function()
		local current_bufnr = tonumber(vim.fn.expand("<abuf>"))
		local term_data = GetCWDTermData()
		local index = nil
		for i, term in ipairs(term_data) do
			if term.bufnr == current_bufnr then
				index = i
				break
			end
		end
		if index then
			term_data[index] = nil
		end
	end,
})

vim.api.nvim_create_autocmd({ "DirChanged", "SessionLoadPost" }, {
	desc = "Update the bufnr of the terminals of this directory",
	group = termnames_augroup,
	pattern = "*",
	callback = function()
		M.update_term_bufnr()
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
