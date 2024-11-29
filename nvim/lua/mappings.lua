local map = vim.keymap.set

-- general mappings
map("n", "<C-s>", "<cmd> w <CR>")
map("i", "jk", "<ESC>")
map("n", "<C-c>", "<cmd> %y+ <CR>") -- copy whole filecontent

map('n', '<C-h>', '<C-w>h', { noremap = true, silent = true })
map('n', '<C-j>', '<C-w>j', { noremap = true, silent = true })
map('n', '<C-k>', '<C-w>k', { noremap = true, silent = true })
map('n', '<C-l>', '<C-w>l', { noremap = true, silent = true })


-- nvimtree
-- hotkeys: https://docs.rockylinux.org/books/nvchad/nvchad_ui/nvimtree/
map("n", "<C-n>", "<cmd> NvimTreeToggle <CR>")
map("n", "T", "<cmd>Lspsaga term_toggle<cr>")

-- Sessions
map("n", "<C-o>", ":SessionSearch<cr>")

-- telescope
map("n", "<C-p>", "<cmd>Telescope find_files<CR>")
map("n", "<leader>fo", "<cmd> Telescope oldfiles <CR>")
map("n", "\\", "<cmd> Telescope live_grep <CR>")
map("n", "<leader>gt", "<cmd> Telescope git_status <CR>")

-- bufferline, cycle buffers
map("n", "<Tab>", "<cmd> BufferLineCycleNext <CR>")
map("n", "<S-Tab>", "<cmd> BufferLineCyclePrev <CR>")
map("n", "<C-w>", "<cmd> bd <CR>")

-- comment.nvim
map("n", "<leader>/", "gcc", { remap = true })
map("v", "<leader>/", "gc", { remap = true })

-- neotest.nvim
map("n", "tn", "<cmd> lua require('neotest').run.run()<CR><BAR><CMD>lua require('neotest').summary.open()<CR>")
map("n", "ta", '<cmd> lua require("neotest").run.run(vim.fn.expand("%"))<CR><BAR><CMD>lua require("neotest").summary.open()<CR>')
map("n", "td", '<cmd> lua require("neotest").run.run({strategy = "dap"})<CR>')
map("n", "tw", '<cmd> lua require("neotest").watch.toggle(vim.fn.expand("%"))<CR>')
map("n", "t[", '<cmd> lua require("neotest").jump.prev({ status = "failed" })<CR>')
map("n", "t]", '<cmd> lua require("neotest").jump.next({ status = "failed" })<CR>')

-- Debugging
map('n', '<F5>', '<cmd>lua require"dap".continue()<CR>', { noremap = true, silent = true })
map('n', 'dc', '<cmd>lua require"dap".continue()<CR>', { noremap = true, silent = true })

map('n', 'dt', '<cmd>lua require"dap".toggle_breakpoint()<CR>', { noremap = true, silent = true })
map('n', 'dC', "<cmd>lua require'dap'.set_breakpoint(vim.fn.input '[Condition] > ')<cr>", { noremap = true, silent = true })
map('n', 'drr', '<cmd>lua require"dap".restart()<CR>', { noremap = true, silent = true })
map('n', 'drf', '<cmd>lua require"dap".restart_frame()<CR>', { noremap = true, silent = true })


map('n', '<F10>', '<cmd>lua require"dap".step_over()<CR>', { noremap = true, silent = true })
map('n', '<F11>', '<cmd>lua require"dap".step_into()<CR>', { noremap = true, silent = true })
map('n', '<F12>', '<cmd>lua require"dap".step_out()<CR>', { noremap = true, silent = true })

map('n', 'di', '<cmd>lua require"dap".step_into()<CR>', { noremap = true, silent = true })
map('n', 'do', '<cmd>lua require"dap".step_over()<CR>', { noremap = true, silent = true })
map('n', 'dO', '<cmd>lua require"dap".step_out()<CR>', { noremap = true, silent = true })

-- Debug UI
map('n', 'db', '<cmd>Telescope dap list_breakpoints<CR>', { noremap = true, silent = true })
map('n', 'du', '<cmd>lua require"dapui".toggle()<CR>', { noremap = true, silent = true })
map('n', 'dR', "<cmd>lua require('dapui').float_element('repl', { width = 100, height = 20, enter = true, position = 'center' })<CR>", { noremap = true, silent = true })


-- format
map("n", "<leader>fm", function()
  require("conform").format({ async = true })
end)
