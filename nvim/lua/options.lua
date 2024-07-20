local o = vim.o

-- vim.api.nvim_create_augroup('remember_cursor_position', {})

-- -- Save the cursor position before leaving the buffer
-- vim.api.nvim_create_autocmd('BufLeave', {
--   group = 'remember_cursor_position',
--   pattern = '*',
--   command = 'call setpos("\'", getpos("."))'
-- })

-- -- Restore the cursor position when opening the file
-- vim.api.nvim_create_autocmd('BufReadPost', {
--   group = 'remember_cursor_position',
--   pattern = '*',
--   callback = function()
--     local line = vim.fn.line
--     if line("'\"") > 1 and line("'\"") <= line("$") then
--       vim.cmd('normal! g`"')
--     end
--   end
-- })

vim.g.mapleader = " "
vim.g.maplocalleader = ' '

o.laststatus = 3 -- global statusline
o.showmode = false

o.clipboard = "unnamedplus"

o.updatetime = 300

-- Indenting
o.expandtab = true
o.shiftwidth = 2
o.smartindent = true
o.tabstop = 2
o.softtabstop = 2

vim.opt.fillchars = { eob = " " }
o.ignorecase = true
o.smartcase = true
o.mouse = "a"

-- Numbers
o.number = true
o.mouse = "a"

o.signcolumn = "yes"
o.splitbelow = true
o.splitright = true
o.termguicolors = true
o.timeoutlen = 300
o.ttimeoutlen = 10 
o.undofile = true

-- add binaries installed by mason.nvim to path
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
vim.env.PATH = vim.env.PATH .. (is_windows and ";" or ":") .. vim.fn.stdpath "data" .. "/mason/bin"
