# termnames.nvim

A simple plugin that adds names to terminals

## Features

- lightweight
- easy to use API

## Requirements

- Neovim >= 0.8.0 (Might work with earlier versions. Haven't tested)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

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

- Accepts one argument as input and creates a terminal with that name

#### TermRename

- Accepts one argument as input and renames active terminal with that name

#### TermClose

- Closes current terminal

### API

#### require("termnames").create_terminal(term_name)

#### require("termnames").get_terminals()

Returns a list containing each terminal's data as a table. The table contains the name, bufnr and id of the terminal

#### require("termnames").get_terminal_name(bufnr)

#### require("termnames").get_current_terminal_name()

#### require("termnames").rename_terminal(new_name)

Rename active terminal with new name.

#### require("termnames").delete_terminal()

Deletes active terminal
