local M = {}

function M.setup()
  require("neotest").setup({
    adapters = {
      require("neotest-python")({
        dap = { justMyCode = false },
        runner = "pytest"
      }),
      require("neotest-go")({
        -- experimental = { 
        --   test_table = true,
        -- },
        args = { "-count=1", "-timeout=60s" }
      }),
      require('neotest-jest')({
        jestCommand = "npm test --",
        jestConfigFile = "jest.config.js",
        env = { CI = true },
        cwd = function(path)
          return vim.fn.getcwd()
        end,
      })
    },
    status = {
        virtual_text = false
    }
  })
end

return M