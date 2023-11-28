local M = {}

local HOME = os.getenv "HOME"
local DEBUGGER_LOCATION = HOME .. "/.local/share/nvim/vscode-chrome-debug"

function M.setup()
  local dap = require "dap"

  dap.adapters.chrome = {
    type = "executable",
    command = "node",
    args = { DEBUGGER_LOCATION .. "/out/src/chromeDebug.js" },
  }

  -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#Javascript
  -- Chrome needs to be started with --remote-debugging-port=9222

  dap.configurations.javascriptreact = {
    {
      type = "chrome",
      request = "attach",
      program = "${file}",
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
      protocol = "inspector",
      port = 9222,
      webRoot = "${workspaceFolder}",
    },
  }

  dap.configurations.typescriptreact = {
    {
      type = "chrome",
      request = "attach",
      program = "${file}",
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
      protocol = "inspector",
      port = 9222,
      webRoot = "${workspaceFolder}",
    },
  }
end

return M
