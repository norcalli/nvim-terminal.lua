# terminal.lua

[![luadoc](https://img.shields.io/badge/luadoc-0.1-blue)](https://norcalli.github.io/luadoc/nvim-terminal.lua/)

A high performance filetype mode for [Neovim](https://github.com/neovim/neovim) which leverages `conceal` and
highlights your buffer with the correct color codes.

## Demo

![Demo](https://raw.githubusercontent.com/norcalli/github-assets/master/nvim-terminal.lua-demo.gif)

## Installation and Usage

Use your plugin manager or clone directly into your `runtimepath`.

```vim
Plug 'norcalli/nvim-terminal.lua'
```

The most basic setup is the following. This will create an `autocmd` to
highlight. Otherwise, only the syntax file with the conceal codes will
be included.

```vim
lua require'terminal'.setup()
```

For more advanced usage, see the [Luadoc documentation](https://norcalli.github.io/luadoc/nvim-terminal.lua/)
or use `:h terminal.lua` once installed.


## TODO

- [ ] Add underline, italic, and other code modes.
- [ ] Look into further performance improvements by eliminating work.
