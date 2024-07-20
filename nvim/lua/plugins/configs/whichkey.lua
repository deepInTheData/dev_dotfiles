local whichkey = require "which-key"

whichkey.setup({
  layout = {
    height = { min = 4, max = 25 },
    width = { min = 20, max = 50 },
    spacing = 3,
    align = "left",
  }  
})

whichkey.add({
  { "<leader>g", group = "git" }, -- git group
  { "<leader>/", desc = "Toogle Comments" }, -- gcc
  { "<leader><C-n>", desc = "Toogle Tree" }, -- nvimtree

  { "<leader>t", group = "tests" }, -- tests group
  { "<leader>tn", "<CMD>lua require('neotest').run.run()<CR><BAR><CMD>lua require('neotest').summary.open()<CR>", desc = "Run NEAREST test and toggle summary", mode = "n" },
  { "<leader>ta", '<CMD>lua require("neotest").run.run(vim.fn.expand("%"))<CR><BAR><CMD>lua require("neotest").summary.open()<CR>', desc = "Run ALL test", mode = "n" },
  { "<leader>td", '<CMD>lua require("neotest").run.run({strategy = "dap"})<CR>', desc = "DEBUG nearest test", mode = "n" },
  { "<leader>ts", '<CMD>lua require("neotest").summary.toggle()<CR>', desc = "Toogle SUMMARY", mode = "n" },
  { "<leader>tw", '<CMD>lua require("neotest").watch.toggle(vim.fn.expand("%"))<CR>', desc = "Toogle WATCH", mode = "n" },
  { "<leader>t[", '<CMD>lua require("neotest").jump.prev({ status = "failed" })<CR>', desc = "Previous FAILED", mode = "n" },
  { "<leader>t]", '<CMD>lua require("neotest").jump.next({ status = "failed" })<CR>', desc = "Next FAILED", mode = "n" },
  
  { "<leader>d", group = "Debug" }, -- Debug group
  -- <cmd> lua require('dapui').open({reset = true})<CR>
  { "<leader>dR", "<cmd>lua require'dap'.restart()<cr>", desc = "Restart", mode = "n" },
  { "<leader>dc", "<cmd>lua require'dap'.continue()<cr>", desc = "Continue", mode = "n" },
  { "<leader>dC", "<cmd>lua require'dap'.set_breakpoint(vim.fn.input '[Condition] > ')<cr>", desc = "Conditional Breakpoint", mode = "n" },
  { "<leader>dd", "<cmd>lua require'dap'.focus_frame()<cr>", desc = "Focus current frame", mode = "n" },
  { "<leader>de", "<cmd>lua require'dapui'.eval()<cr>", desc = "Evaluate", mode = "n" },
  { "<leader>di", "<cmd>lua require'dap'.step_into()<cr>", desc = "Step Into", mode = "n" },
  { "<leader>do", "<cmd>lua require'dap'.step_over()<cr>", desc = "Step Over", mode = "n" },
  { "<leader>dO", "<cmd>lua require'dap'.step_out()<cr>", desc = "Step Out", mode = "n" },

  { "<leader>dj", "<cmd>lua require'dap'.up()<cr>", desc = "Go up the stack frame", mode = "n" },
  { "<leader>dk", "<cmd>lua require'dap'.down()<cr>", desc = "Go down the stack frame", mode = "n" },
  { "<leader>dt", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", desc = "Toggle Breakpoint", mode = "n" },
  { "<leader>dx", "<cmd>lua require'dap'.terminate()<cr>", desc = "Terminate", mode = "n" },
  { "<leader>dh", "<cmd>lua require'dap.ui.widgets'.hover()<cr>", desc = "Hover Variables", mode = "n" },

  -- DAP UI telescope
  { "<leader>db", "<cmd>Telescope dap list_breakpoints<cr>", desc = "Telescope list breakpoints", mode = "n" },
  { "<leader>df", "<cmd>Telescope dap frames<cr>", desc = "Telescope frames", mode = "n" },
  { "<leader>dr", "<cmd>lua require('dapui').float_element('repl', { width = 100, height = 20, enter = true, position = 'center' })<cr>", desc = "Telescope Toogle Repl", mode = "n" },
  { "<leader>dw", "<cmd>lua require('dapui').float_element('watches', { width = 100, height = 20, enter = true, position = 'bottom' })<cr>", desc = "Telescope Toogle Watch", mode = "n" },
  { "<leader>du", "<cmd>lua require'dapui'.toggle()<cr>", desc = "Telescope DAP UI", mode = "n" },

  -- DAP variables 
  { "<leader>dv", "<cmd>lua require'telescope'.extensions.dap.variables{}<cr>", desc = "View variables", mode = "n" },

  { "<leader>f", group = "file" }, -- file group
  { "<leader>ff", "<CMD>Telescope find_files<cr>", desc = "Find File", mode = "n" },
  { "<leader>fm", desc = "Format File", mode = "n" },
  { "<leader>f\\", "<CMD>Telescope live_grep<cr>", desc = "Grep", mode = "n" },

  
  { "<leader>b", group = "buffers", expand = function()
      return require("which-key.extras").expand.buf()
    end
  },
  { "<leader>b<Tab>", "<cmd> BufferLineCycleNext <CR>", desc = "next buffer", mode = "n" },
  { "<leader>b<S-Tab>", "<cmd> BufferLineCyclePrev <CR>", desc = "previous buffer", mode = "n" },
  { "<leader>b<C-q>", "<cmd> bd <CR>", desc = "buffer delete", mode = "n" },
})

