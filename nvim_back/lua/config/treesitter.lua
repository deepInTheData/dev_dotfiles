local M = {}

function M.setup()
  require("nvim-treesitter.configs").setup {
    -- One of "all", "maintained" (parsers with maintainers), or a list of languages
    -- ensure_installed = { "c", 
    -- "cpp", 
    -- "comment", 
    -- "html", 
    -- "markdown", 
    -- "lua", 
    -- "python", 
    -- "graphql", 
    -- "go", 
    -- "typescript", 
    -- "javascript", "jsdoc", "json", "sql", "scss", "vim"  },

    -- Install languages synchronously (only applied to `ensure_installed`)
    sync_install = false,

    highlight = {
      -- `false` will disable the whole extension
      enable = true,
    },


    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn",
        node_incremental = "grn",
        scope_incremental = "grc",
        node_decremental = "grm",
      },
    },

    indent = { enable = true, disable = { "python", "java", "rust", "lua" } },

    -- vim-matchup
    matchup = {
      enable = true,
    },

    -- nvim-treesitter-textsubjects
    textsubjects = {
      enable = true,
      prev_selection = ",", -- (Optional) keymap to select the previous selection
      keymaps = {
        ["."] = "textsubjects-smart",
        [";"] = "textsubjects-container-outer",
        ["i;"] = "textsubjects-container-inner",
      },
    },


    -- nvim-treesitter-textobjects 
    -- Alternative is coc-funcobj
    textobjects = {
      select = {
        enable = true,

        -- Automatically jump forward to textobj, similar to targets.vim
        lookahead = true,

        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
        },
      },

      -- swap parameter positions
      swap = {
        enable = true,
        swap_next = {
          ["<leader>cx"] = "@parameter.inner",
        },
        swap_previous = {
          ["<leader>cX"] = "@parameter.inner",
        },
      },

      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = "@class.outer",
        },
        goto_next_end = {
          ["]M"] = "@function.outer",
          ["]["] = "@class.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[["] = "@class.outer",
        },
        goto_previous_end = {
          ["[M"] = "@function.outer",
          ["[]"] = "@class.outer",
        },
      },

      -- show textobject surrounding definition as determined using Neovim's built-in LSP in a floating window. 
      -- Press the shortcut twice to enter the floating window
      -- lsp_interop = {
      --   enable = true,
      --   border = "none",
      --   peek_definition_code = {
      --     ["<leader>cf"] = "@function.outer",
      --     ["<leader>cF"] = "@class.outer",
      --   },
      -- },
    },

    -- autotag
    autotag = {
      enable = true,
    },

    -- context_commentstring
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
    },

  }
end

return M
