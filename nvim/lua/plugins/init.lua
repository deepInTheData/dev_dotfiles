local plugins = {
  { lazy = true, "nvim-lua/plenary.nvim" },

  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = true,
  },

  -- sessions 
  {
    'rmagatti/auto-session',
    lazy = false,
    dependencies = {
      'nvim-telescope/telescope.nvim', -- Only needed if you want to use session lens
    },

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
      -- log_level = 'debug',
    },
    -- config = function()
    --   require('auto-session').setup({
    --     auto_restore_last_session = true,
    --     auto_create = function()
    --       local cmd = 'git rev-parse --is-inside-work-tree'
    --       return vim.fn.system(cmd) == 'true\n'
    --     end,
    --   })      
    -- end,
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


  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = {
      "nvim-treesitter/nvim-treesitter"
    }
  },  
  -- syntax highlighting
  -- {
  --   "nvim-treesitter/nvim-treesitter",
  --   build = ":TSUpdate",
  --   config = function()
  --     require "plugins.configs.treesitter"
  --   end,
  -- },
  -- -- text objects
  -- {
  --   "nvim-treesitter/nvim-treesitter-textobjects",
  --   config = function()
  --     require "plugins.configs.treesitter-objects"
  --   end,    
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter"
  --   }
  -- },

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
  {
    'nvimdev/lspsaga.nvim',
    config = function()
        require('lspsaga').setup({
          finder = {
            keys = {
              vsplit = 's'
              -- shuttle = '[w' shuttle bettween the finder layout window
              -- toggle_or_open = 'o' toggle expand or open
              -- vsplit = 's' open in vsplit
              -- split = 'i' open in split
              -- tabe = 't' open in tabe
              -- tabnew = 'r' open in new tab
              -- quit = 'q' quit the finder, only works in layout left window
              -- close = '<C-c>k' close finder              
            }
          }
        })        
    end,
    dependencies = {
        'nvim-treesitter/nvim-treesitter', -- optional
        'nvim-tree/nvim-web-devicons',     -- optional
    }
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
  {
    'nvim-telescope/telescope-fzf-native.nvim', 
    build = 'make',
    config = function()
    end
  },


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

  {
    'tpope/vim-rails',
    -- Optionally, add config or other settings here
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
  {
    "sindrets/diffview.nvim"
  },

  -- avante.nvim
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    opts = {
      -- add any opts here
    },
    keys = { -- See https://github.com/yetone/avante.nvim/wiki#keymaps for more info
      { "<leader>aa", function() require("avante.api").ask() end, desc = "avante: ask", mode = { "n", "v" } },
      { "<leader>ar", function() require("avante.api").refresh() end, desc = "avante: refresh", mode = "v" },
      { "<leader>ae", function() require("avante.api").edit() end, desc = "avante: edit", mode = { "n", "v" } },
    },
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      -- {
      --   -- support for image pasting
      --   "HakonHarnes/img-clip.nvim",
      --   event = "VeryLazy",
      --   opts = {
      --     -- recommended settings
      --     default = {
      --       embed_image_as_base64 = false,
      --       prompt_for_file_name = false,
      --       drag_and_drop = {
      --         insert_mode = true,
      --       },
      --       -- required for Windows users
      --       use_absolute_path = true,
      --     },
      --   },
      -- },
      {
        -- Make sure to setup it properly if you have lazy=true
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },

  -- sql
  {
    "kndndrj/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    build = function()
      -- Install tries to automatically detect the install method.
      -- if it fails, try calling it with one of these parameters:
      --    "curl", "wget", "bitsadmin", "go"
      require("dbee").install()
    end,
    config = function()
      require("dbee").setup()
    end,
  }

}

require("lazy").setup(plugins, require "lazy_config")
