local M = {}

-- vscode-js-debug  should be used but not really working out of the box yet
-- Keep a look out for  
-- https://github.com/mxsdev/nvim-dap-vscode-js

local HOME = os.getenv "HOME"
local DEBUGGER_LOCATION = HOME .. "/.local/share/nvim/vscode-node-debug2"

function M.setup()
  local dap = require "dap"

  dap.adapters.node2 = {
    type = "executable",
    command = "node",
    
    args = {
      DEBUGGER_LOCATION .. "/out/src/nodeDebug.js",
    },
  }

  dap.configurations.javascript = {
    {
      name = 'Launch',
      type = "node2",
      request = "launch",
      program = "${file}",
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
      protocol = "inspector",
      console = "integratedTerminal",
    },
    {
      -- For this to work you need to make sure the node process is started with the `--inspect` flag.
      name = 'Attach to process',
      type = 'node2',
      request = 'attach',
      protocol = "inspector",
      processId = require'dap.utils'.pick_process,
    }
  }

  dap.configurations.typescript = {
    {
      name = 'Launch',
      type = "node2",
      request = "launch",
      program = "${file}",
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
      protocol = "inspector",
      console = "integratedTerminal",
    },
    {
      -- For this to work you need to make sure the node process is started with the `--inspect` flag.
      name = 'Attach to process',
      type = 'node2',
      request = 'attach',
      protocol = "inspector",
      processId = require'dap.utils'.pick_process,
    }
  }

end

return M
