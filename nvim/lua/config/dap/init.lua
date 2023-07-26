local M = {}

-- TODO:
-- https://github.com/harrisoncramer/nvim/blob/main/lua/plugins/dap/init.lua
local function configure()
  --local dap_install = require("dap-install")
  --dap_install.setup {
  --  installation_path = vim.fn.stdpath "data" .. "/dapinstall/",
  --}
-- local mason = require("mason")
-- mason.setup()

-- local mason_dap = require("mason-nvim-dap")
-- mason_dap.setup({
--   ensure_installed = { "python" },
--   -- handlers = {},
--   automatic_installation = true
-- })

  local dap_breakpoint = {
    error = {
      text = "🟥",
      texthl = "LspDiagnosticsSignError",
      linehl = "",
      numhl = "",
    },
    rejected = {
      text = "R",
      texthl = "LspDiagnosticsSignHint",
      linehl = "",
      numhl = "",
    },
    stopped = {
      text = "⭐️",
      texthl = "LspDiagnosticsSignInformation",
      linehl = "DiagnosticUnderlineInfo",
      numhl = "LspDiagnosticsSignInformation",
    },
  }

  vim.fn.sign_define("DapBreakpoint", dap_breakpoint.error)
  vim.fn.sign_define("DapStopped", dap_breakpoint.stopped)
  vim.fn.sign_define("DapBreakpointRejected", dap_breakpoint.rejected)
end

local function configure_exts()
  require("nvim-dap-virtual-text").setup {
     commented = true,
  }

  require("telescope").load_extension "dap"
  local dap, dapui = require "dap", require "dapui"
  dap.set_log_level("TRACE")

  
  dapui.setup {} -- use default
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
end

local function configure_debuggers()
  -- require("config.dap.lua").setup()
  require("config.dap.python").setup()
  require("config.dap.go").setup()
  -- require("config.dap.kotlin").setup()
  -- require("config.dap.react_chrome").setup()
  -- require("config.dap.node").setup()  
end

function M.setup()
  configure() -- Configuration
  configure_exts() -- Extensions
  configure_debuggers() -- Debugger
  require("config.dap.keymaps").setup() -- Keymaps
end


return M
