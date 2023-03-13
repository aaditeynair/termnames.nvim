# termnames.nvim

A simple plugin that adds names to terminals

![demo image](https://user-images.githubusercontent.com/85427178/224555211-99160423-dbd6-4df5-a8dd-7d3e8b1592c1.png)

## Note

termnames.nvim is a work is progress. There might be several bugs and a few quirks. If you find a bug, feel free to open an issue and if you find a fix, please open a pull request.

termnames.nvim works seamlessly with my config but you might have a few problems with yours. For the plugin to perform perfectly, it is required for `TermSave` or `save_terminal_data()` to run before `mksession`. termnames.nvim also needs `TermRefresh` or `update_term_bufnr()` to run after loading a session or a new working directory. This is easy to implement if your session manager provides hooks. If you find or know a way to make this automatic for a session manager or for all session managers, please open a issue or a pull request. I will be more than happy to make termnames.nvim better.

## Features

- lightweight
- easy to use API

## Requirements

- Neovim >= 0.8.0 (Might work with earlier versions. Haven't tested)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [bufdelete.nvim](https://github.com/famiu/bufdelete.nvim)

## Installation

With lazy.nvim

```lua
return {
    "aaditeynair/termnames.nvim",
    cmd = {"TermOpen", "TermRename", "TermClose"}
}
```

## Usage

### Commands

#### TermOpen

- Passing a name to the command creates a terminal with that name
- Not giving a name creates a terminal with an automatic name

#### TermRename

- Accepts one or two arguments
- First argument is the new name
- Second argument is optional. It is the name of the terminal which is to be changed

#### TermClose

- Closes open terminal if called without arguments
- Pass the name of a terminal to close that terminal

#### TermSave

- Saves the terminal data and closes the terminal buffer
- Call before `mksession`. Otherwise you will have extra terminal buffers in the next session
- Automatically called on `ExitPre`

#### TermRefresh

- Call command to reopen the terminal buffers and update the buffer handles
- Call after loading a new directory or loading a session

### API

#### require("termnames").create_terminal(term_name)

- `term_name` must be a string

#### require("termnames").get_terminals()

- Returns a list containing each terminal's data as a table

```json
{
  "id": 1,
  "name": "term1",
  "bufnr": 3
}
```

#### require("termnames").get_terminal_name(bufnr)

- Pass the `bufnr` of a terminal buffer to get its name

#### require("termnames").get_current_terminal_name()

- Returns the name of the current terminal
- Can be used in statuslines, winbars, etc. Example given below

#### require("termnames").rename_terminal(args)

- If `args` is a string, the active terminal is renamed to args
- If `args` is table, the first item is taken as the new name and the second item as the name of the terminal to be changed

#### require("termnames").delete_terminal({term_name})

- If `term_name` is provided then the terminal with that name is deleted
- Otherwise the active terminal is deleted

#### require("termnames").save_terminal_data()

- Saves the terminal data and closes buffers
- Call before your session is saved. Automatically called on `ExitPre`

#### require("termnames").update_term_bufnr()

- Cycles through the data and opens terminal buffers and updates the buffer handles
- Must be called after loading a session or changing the directory
- Runs on `DirChanged` and `SessionLoadPost` but it is a bit finicky. Recommended to run on your own

### Example

#### Lualine

```lua
local function get_term_name()
    return require("termnames").get_current_terminal_name()
end

...

{
	get_term_name,
	cond = function()
    	return vim.api.nvim_buf_get_name(0):find("^term://") ~= nil
	end,
},

```
