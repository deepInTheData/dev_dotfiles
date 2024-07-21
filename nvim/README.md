# TinyVim
- Minimal Neovim config meant to be a starting point for new neovim users.


# Install

# Dir structure
```bash
├── init.lua
├── lua
    ├── commands.lua
    ├── mappings.lua
    ├── options.lua
    └── plugins
        ├── init.lua
        ├── configs
            ├── cmp.lua
            ├── telescope.lua
            └── ( more ... )
```
# About
- Dont expect this config to be beautiful or blazing fast (no hardcore lazyloading is done)! 
- I'm just using some plugins with their default configs
- This config only uses only lesser plugins which I think are important for any config.

# Important Plugins used
Below is the list of some very important plugins which I think should be must for any neovim config.

| Name             | Description                                  |
|-------------------------|----------------------------------------------|
| nvim-tree.lua           | File tree                                    |
| Nvim-web-devicons       | Icons provider                               |
| nvim-treesitter         | Configure treesitter                         |
| bufferline.nvim         | Tab + bufferline plugin                      |
| nvim-cmp                | Autocompletion                               |
| Luasnip & friendly snippets               | Snippets                                      |
| mason.nvim              | Download binaries of various lsps, formatters, debuggers, etc. |
| gitsigns.nvim                | Git-related features                         |
| comment.nvim            | Commenting                                   |
| telescope.nvim          | Fuzzy finder                                 |
| conform.nvim            | Formatter                                    |
