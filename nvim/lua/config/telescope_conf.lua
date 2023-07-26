-- require"telescope.builtin".find_files(require"telescope.themes".get_ivy({layout_config={preview_width=0.8}}))

local M = {}

function M.setup() 
  require("telescope").setup{
    defaults = {
      prompt_prefix = "> ",
      selection_caret = "> ",
      theme = "ivy"
    },
    pickers = {
      find_files = {
        theme = "dropdown",
        previewer = false
      },
      live_grep = {
        theme = "ivy",
        only_sort_text = true
      },
      buffers = {
        theme = "ivy"
      },
      current_buffer_tags = {
        theme = "ivy"
      }
    },
    extensions = {
      fzf = {
        fuzzy = true,                    
        override_generic_sorter = true,  
        override_file_sorter = true,     
        case_mode = "smart_case"
      },
      coc = { theme = 'ivy' }
    }
  }
  -- local open_dir = function(config)
  --     local opt = require('telescope.themes').get_ivy {
  --         cwd = config.dir,
  --         prompt_title = config.title,
  --         shorten_path = true
  --     }
  --     require('telescope.builtin').find_files(opt)
  -- end
  
  
  -- local builtin = require('telescope.builtin')
  -- local ivy_theme = require('telescope.themes').get_ivy()

  require('telescope').load_extension('fzf')
  require('telescope').load_extension('coc')
--  require("telescope").load_extension("file_browser")
end

return M
-- require('telescope').load_extension('fzf')
-- require('telescope').load_extension('coc')

