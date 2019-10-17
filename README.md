# terminal.lua

[![luadoc](https://img.shields.io/badge/luadoc-0.1-blue)](https://norcalli.github.io/luadoc/nvim-terminal.lua/)

A high performance filetype mode for [Neovim](https://github.com/neovim/neovim) which leverages `conceal` and
highlights your buffer with the correct color codes.

## Demo

![Demo](https://raw.githubusercontent.com/norcalli/github-assets/master/nvim-terminal.lua-demo.gif)

![Demo.mp4](https://raw.githubusercontent.com/norcalli/github-assets/master/nvim-terminal.lua-demo.mp4)

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

Then you can just `setl filetype=terminal` to activate the mode.

**NOTE:** If you want to completely hide the color codes, you can use `concealcursor` (`:h concealcursor`) to that effect. Setting it to `setl concealcursor=nc` would hide the codes until you went into visual mode or insert mode. **This may make it seem like the cursor is lagging when you are travelling over text, but the cursor doesn't move if it is over hidden codes**, so be aware of that effect.

For more advanced usage, see the [Luadoc documentation](https://norcalli.github.io/luadoc/nvim-terminal.lua/)
or use `:h terminal.lua` once installed.


## TODO

- [ ] Add underline, italic, and other code modes.
- [ ] Look into further performance improvements by eliminating work.
- [ ] See if I can get fenced blocks to work in `markdown` mode.
