local M = {}

function M.setup(_)
  require("dap-python").setup("python", {})

  -- table.insert(dap.configurations.python, {
  --     type = 'python',
  --     request = 'launch',
  --     name = 'FastAPI',
  --     program = vim.fn.getcwd() .. '/main.py',
  --     pythonPath = function()
  --         return 'python'
  --     end,
  -- })
  -- table.insert(dap.configurations.python, {
  --     type = 'python',
  --     request = 'launch',
  --     name = 'FastAPI module',
  --     module = 'uvicorn',
  --     args = {
  --         'main:app',
  --         -- '--reload',
  --         '--use-colors',
  --     },
  --     pythonPath = 'python',
  --     console = 'integratedTerminal',
  -- })  

  -- https://github.com/mfussenegger/nvim-dap/wiki/Local-and-Remote-Debugging-with-Docker
  table.insert(require("dap").configurations.python, {
    type = "python",
    request = "attach",
    connect = {
      port = function()
        return tonumber(vim.fn.input("Port [5678]: ")) or 5678
      end,
      host = "127.0.0.1",
    },
    mode = "remote",
    name = "Container Attach Debug",
    cwd = vim.fn.getcwd(),
    pathMappings = {
      {
        localRoot = function()
          return vim.fn.input("Local code folder > ", vim.fn.getcwd(), "file")
          -- Local folder the code lives
        end,
        remoteRoot = function()
          return vim.fn.input("Container code folder > ", "/", "file")
          -- Wherever your Python code lives in the container.
        end,
      },
    },
  })
end

return M
