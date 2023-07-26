local g = vim.g

local default_opts = { noremap = true, silent = true }
local expr_opts = { noremap = true, expr = true, silent = true }

local keymap = vim.keymap.set
local nkeymap = vim.api.nvim_set_keymap

-- source: https://vim.fandom.com/wiki/Mapping_keys_in_Vim_-_Tutorial_(Part_1)
-- Commands                        Mode
-- --------                        ----
-- nmap, nnoremap, nunmap          Normal mode
-- imap, inoremap, iunmap          Insert and Replace mode
-- vmap, vnoremap, vunmap          Visual and Select mode
-- xmap, xnoremap, xunmap          Visual mode
-- smap, snoremap, sunmap          Select mode
-- cmap, cnoremap, cunmap          Command-line mode
-- omap, onoremap, ounmap          Operator pending mode

-- Space as leader key
keymap("", "<Space>", "<Nop>", default_opts)
g.mapleader = " "
g.maplocalleader = " "

-- Non leader keys defined here.
-- Leader keys defined in whichkey.lua

nkeymap("n", "<F2>", "<Plug>(coc-rename)", { silent = true })
nkeymap("n", "<F3>", ":ZenMode <CR>", { silent = true })
nkeymap("n", "<F4>", ":Twilight <CR>", { silent = true })
nkeymap("n", "<leader><C-b>", ":NvimTreeToggle <CR>", { silent = true })


-- jk to ESC
keymap("i", "jk", "<ESC>", default_opts)

-- Center search results
keymap("n", "n", "nzz", default_opts)
keymap("n", "N", "Nzz", default_opts)

-- Switch buffer Shift-h or Shift-l
keymap("n", "<S-h>", ":BufferLineCyclePrev<CR>", default_opts)
keymap("n", "<S-l>", ":BufferLineCycleNext<CR>", default_opts)

--
-- va}a} visual select block recur
-- yiB yank inner block
nkeymap("i", "<F5>", "<C-R>=expand('%:p:h')<CR>", default_opts)

nkeymap("v", "<leader>s", ":sort i <CR>", {})
nkeymap("v", "<leader>S", ":sort u <CR>", {})

nkeymap("n", "<leader>h", ":call CocActionAsync('doHover')<CR>", default_opts)

-- Diagnostics
-- nkeymap("n", "<leader>[", "<Plug>(coc-diagnostic-prev)", {})
-- nkeymap("n", "<leader>]", "<Plug>(coc-diagnostic-next)", {})


-- https://github.com/neoclide/coc.nvim/pull/3862
nkeymap("i", "<C-Space>", "coc#refresh()", expr_opts)
nkeymap("i", "<TAB>", "coc#pum#visible() ? coc#pum#next(1) : \"<TAB>\"", expr_opts)
nkeymap("i", "<S-TAB>", "coc#pum#visible() ? coc#pum#prev(1) : \"<C-h>\"", expr_opts)
nkeymap("i", "<CR>", "coc#pum#visible() ? coc#pum#confirm() : '<C-g>u<CR><c-r>=coc#on_enter()<CR>'", expr_opts)

-- telescope
-- keymap("n", "<C-P>", "<cmd> lua require'telescope.builtin'.find_files({cwd = \"%:h\"}) <CR>", {silent = true, noremap = true})
keymap("n", "<C-P>", "<cmd> lua require'telescope.builtin'.find_files() <CR>", {silent = true, noremap = true})
nkeymap("n", "\\", "<cmd> Telescope live_grep <CR>", {silent = true, noremap = true})
