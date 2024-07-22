local plugins = {
  { lazy = true, "nvim-lua/plenary.nvim" },

  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = true,
  },

  -- file tree
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    config = function()
      require("nvim-tree").setup()
    end,
  },

  -- icons, for UI related plugins
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").setup()
    end,
  },

  -- syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require "plugins.configs.treesitter"
    end,
  },

  -- buffer + tab line
  {
    "akinsho/bufferline.nvim",
    event = "BufReadPre",
    config = function()
      require "plugins.configs.bufferline"
    end,
  },

  -- statusline

  {
    "echasnovski/mini.statusline",
    config = function()
      require("mini.statusline").setup { set_vim_settings = false }
    end,
  },

  -- we use cmp plugin only when in insert mode
  -- so lets lazyload it at InsertEnter event, to know all the events check h-events
  -- completion , now all of these plugins are dependent on cmp, we load them after cmp
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      -- cmp sources
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lua",

      -- snippets
      --list of default snippets
      "rafamadriz/friendly-snippets",

      -- snippets engine
      {
        "L3MON4D3/LuaSnip",
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },

      -- autopairs , autocompletes ()[] etc
      {
        "windwp/nvim-autopairs",
        config = function()
          require("nvim-autopairs").setup()

          --  cmp integration
          local cmp_autopairs = require "nvim-autopairs.completion.cmp"
          local cmp = require "cmp"
          cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
      },
    },
    config = function()
      require "plugins.configs.nvimcmp"
    end,
  },

  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonInstall" },
    config = function()
      require("mason").setup()
    end,
  },

  -- lsp
  -- install other deps: npm install -g typescript typescript-language-server
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require "plugins.configs.lspconfig"
    end,
  },

  -- formatting , linting
  {
    "stevearc/conform.nvim",
    lazy = true,
    config = function()
      require "plugins.configs.conform"
    end,
  },

  -- files finder etc
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    config = function()
      require "plugins.configs.telescope"
    end,
  },
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },


  -- which key setup
  { 'folke/which-key.nvim',
    event = "VeryLazy",
    config = function()
      require("plugins.configs.whichkey")
    end,
  },

  -- comment
  {
      'numToStr/Comment.nvim',
      opts = {
          -- add any options here
      }
  },

  -- Tests
  {
    "vim-test/vim-test",
    config = function()  
      require "plugins.configs.vimtest"
    end,
  },

  -- {
  --   "nvim-neotest/neotest-vim-test"
  -- },

  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require "plugins.configs.neotest"
    end,
  },
  -- Test plugins
  {
    "nvim-neotest/neotest-python",
    ft = { 'python' },
    dependencies = {
      "nvim-neotest/neotest",
    },
  },
  {
    "haydenmeade/neotest-jest",
    ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    dependencies = {
      "nvim-neotest/neotest",
    },
  },  
  {
    "olimorris/neotest-rspec",
    ft = { 'ruby' },
    dependencies = {
      "nvim-neotest/neotest",
    },
  },    
  {
    "rcasia/neotest-java",
    dependencies = {
      "nvim-neotest/neotest",
    },
  },   


  -- DAP debug 
  {
    "mfussenegger/nvim-dap",
    config = function()
      require "plugins.configs.dap"
    end    
  },
  -- DAP Extensions
  {
    'mfussenegger/nvim-dap-python',
    -- ft = { 'python' },
    dependencies = { 'mfussenegger/nvim-dap' },
    -- config = function()
    --   require("plugins.configs.dap.python")      
    -- end
  },

  { 
    "niuiic/dap-utils.nvim",
    dependencies = { 'mfussenegger/nvim-dap' } 
  },
  {
    "suketa/nvim-dap-ruby",
    dependencies = { 'mfussenegger/nvim-dap' } 
  }, 
  { 
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { 'mfussenegger/nvim-dap' }
  },
  { 
    "nvim-telescope/telescope-dap.nvim",
    dependencies = { 'mfussenegger/nvim-dap' }
  },
  { 
    "rcarriga/nvim-dap-ui",
    dependencies = { 'mfussenegger/nvim-dap' }
  },  

  -- DAP for JS
  {
    "microsoft/vscode-js-debug",
    build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
  },
  {
    "mxsdev/nvim-dap-vscode-js",
    dependencies = { 
      'mfussenegger/nvim-dap',  
      'microsoft/vscode-js-debug',
    },
    -- opts = {
    --   debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
    -- },        
  },

  -- git status on signcolumn etc
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup()
    end,
  },
}

require("lazy").setup(plugins, require "lazy_config")