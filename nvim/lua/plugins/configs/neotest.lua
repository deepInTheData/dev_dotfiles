require('neotest').setup({
  adapters = {
    require('neotest-jest')({
      jestCommand = "npm test --",
      jestConfigFile = "jest.config.js",
      env = { CI = true },
      cwd = function()
        return vim.fn.getcwd()
      end,
    }),

    -- Python slow to load when testing. Just use vim-test..
    -- require('neotest-python')({
    --   dap = { justMyCode = false },
    --   runner = 'pytest',
    --   args = {"--log-level", "DEBUG"},
    -- }),

    require("neotest-rspec")

  }
})