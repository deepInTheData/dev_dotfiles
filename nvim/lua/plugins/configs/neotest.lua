require('neotest').setup({
  adapters = {
    -- python
    require('neotest-python')({
      dap = { justMyCode = false },
      runner = 'pytest',
      args = {"--log-level", "DEBUG"},
    }),
    -- jest
    require('neotest-jest')({
      jestCommand = "npm test --",
      jestConfigFile = "jest.config.js",
      env = { CI = true },
      cwd = function()
        return vim.fn.getcwd()
      end,
    }),
    -- ruby
    require("neotest-rspec")
  },
})

