local Path = require("plenary.path")
local data_location = vim.fn.stdpath("data") .. "/termnames.json"

local M = {}
M.update_term_bufnr_events = { "SessionLoadPost" }
M.close_keybinding = "<leader>q"

TerminalData = TerminalData or {}

-- Global functions

function GetCWDTermData()
    local cwd = vim.fn.getcwd()
    TerminalData[cwd] = TerminalData[cwd] or {}
    return TerminalData[cwd]
end

function HasValue(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function M.setup(opts)
    local events = opts.events
    local keybinding = opts.close_term_keybinding

    if type(events) == "table" or type(events) == "string" then
        M.update_term_bufnr_events = events
    end

    if type(keybinding) == "string" then
        M.close_keybinding = keybinding
    end
end

-- Create terminal (CREATE)
function M.create_terminal(opts)
    vim.cmd("terminal")

    vim.cmd("setlocal nonumber norelativenumber")
    vim.keymap.set("n", M.close_keybinding, "<CMD>TermClose<CR>", {
        silent = true,
        buffer = 0,
    })

    local term_data = GetCWDTermData()

    local terminal_name, cmd = "", ""

    if type(opts) == "string" then
        terminal_name = opts
    elseif type(opts) == "table" then
        terminal_name = opts[1]
        for i = 2, #opts, 1 do
            local whitespace = " "
            if i == 2 then
                whitespace = ""
            end

            cmd = cmd .. whitespace .. opts[i]
        end
    end

    local id = 1
    if term_data[1] then
        id = term_data[#term_data].id + 1
    end

    if terminal_name == "" then
        terminal_name = "term" .. tostring(id)
    end

    local new_term = {
        ["name"] = terminal_name,
        ["bufnr"] = vim.api.nvim_win_get_buf(0),
        ["id"] = id,
    }
    table.insert(term_data, new_term)

    if cmd ~= "" then
        M.run_terminal_cmd({ terminal_name, cmd })
    end
end

-- Get data about terminals (READ)
function M.get_terminals()
    return GetCWDTermData()
end

function M.get_terminal_name(bufnr)
    local term_data = GetCWDTermData()
    for _, term in ipairs(term_data) do
        if term.bufnr == bufnr then
            return term.name
        end
    end
end

function M.get_current_terminal_name()
    local current_bufnr = vim.api.nvim_win_get_buf(0)
    return M.get_terminal_name(current_bufnr)
end

function M.terminal_exists(term_name)
    local term_data = GetCWDTermData()
    for _, term in ipairs(term_data) do
        if term.name == term_name then
            return true
        end
    end
    return false
end

-- Rename terminal (UPDATE)
function M.rename_terminal(opts)
    local term_data = GetCWDTermData()

    local new_name, old_name
    if type(opts) == "table" then
        new_name = opts[1]
        old_name = opts[2]
    else
        new_name = opts
        old_name = nil
    end

    if old_name ~= nil then
        for _, term in ipairs(term_data) do
            if term.name == old_name then
                term.name = new_name
            else
                print("Current buffer is not in the terminal list")
            end
        end
    else
        local bufnr = vim.api.nvim_win_get_buf(0)
        for _, term in ipairs(term_data) do
            if term.bufnr == bufnr then
                term.name = new_name
            else
                print("Current buffer is not in the terminal list")
            end
        end
    end
end

-- Delete terminal (DELETE)
function M.delete_terminal(name)
    local term_data = GetCWDTermData()

    local bdelete_exists, bdelete = pcall(require, "bufdelete")
    if name ~= "" then
        for _, term in ipairs(term_data) do
            if term.name == name then
                if bdelete_exists then
                    bdelete.bufdelete(term.bufnr, true)
                else
                    vim.cmd("bd!" .. term.bufnr)
                end
                return
            end
        end
        print("Terminal called " .. name .. " doesn't exist")
    else
        local bufnr = vim.api.nvim_win_get_buf(0)
        for _, term in ipairs(term_data) do
            if term.bufnr == bufnr then
                if bdelete_exists then
                    bdelete.bufdelete(0, true)
                else
                    vim.cmd("split | bnext")
                    vim.cmd("wincmd p | bd!")
                end
                return
            end
        end
        print("Current buffer is not in the terminal list")
    end
end

--  Run commands for terminal

function M.run_terminal_cmd(opts)
    local term_data = GetCWDTermData()

    if not type(opts) == "table" then
        print("Options must be passed as a table in the form of {term_name, cmd}")
        return nil
    end

    local term_name = opts[1]
    local cmd = ""
    for i = 2, #opts, 1 do
        local whitespace = " "
        if i == 2 then
            whitespace = ""
        end

        cmd = cmd .. whitespace .. opts[i]
    end

    if term_name == nil or cmd == nil then
        print("Supply both the term_name and cmd in a table as opts. ")
        return
    end

    local terminal = nil
    for _, term in ipairs(term_data) do
        if term.name == term_name then
            terminal = term
            break
        end
    end

    if terminal ~= nil then
        local term_job_id = vim.api.nvim_buf_get_var(terminal.bufnr, "terminal_job_id")
        vim.fn.chansend(term_job_id, cmd .. "\n")
    else
        print("Terminal with name " .. term_name .. " doesn't exist")
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

    M.close_term_buffers()
end

function M.close_term_buffers()
    local terminal_data = GetCWDTermData()
    for _, term in ipairs(terminal_data) do
        if HasValue(vim.api.nvim_list_bufs(), term.bufnr) then
            vim.api.nvim_buf_delete(term.bufnr, { force = true })
        end
    end
end

function M.restore_terminals()
    local file = Path:new(data_location)
    if not file:exists() then
        file:touch()
        file:write(vim.json.encode({}), "w")
    end
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
    local used_buf_handles = {}

    local function create_new_term_buffer(terminal)
        local original_bufnr = vim.api.nvim_win_get_buf(0)

        vim.cmd("terminal")
        vim.cmd("setlocal nonumber norelativenumber")
        vim.keymap.set("n", M.close_keybinding, "<CMD>TermClose<CR>", {
            silent = true,
            buffer = 0,
        })

        local new_bufnr = vim.api.nvim_win_get_buf(0)
        terminal.bufnr = new_bufnr
        vim.api.nvim_win_set_buf(0, original_bufnr)
    end

    for _, terminal in ipairs(term_data) do
        local bufnr = terminal.bufnr
        -- check if buffer with this handle exists
        if HasValue(vim.api.nvim_list_bufs(), bufnr) then
            -- check if the buffer is a terminal
            if vim.api.nvim_buf_get_name(bufnr):find("^term://") ~= nil then
                -- if it is a terminal, check if the handle has been used by other terminals
                if HasValue(used_buf_handles, bufnr) then
                    create_new_term_buffer(terminal)
                else
                    terminal.bufnr = bufnr
                    table.insert(used_buf_handles, bufnr)
                end
            else
                create_new_term_buffer(terminal)
            end
        else
            create_new_term_buffer(terminal)
        end
    end
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
            table.remove(term_data, index)
        end
    end,
})

vim.api.nvim_create_autocmd(M.update_term_bufnr_events, {
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
