require("telescope").setup {
  defaults = {
    sorting_strategy = "ascending",
    layout_config = {
      horizontal = { prompt_position = "top" },
    },
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
    }
  }  
}


require('telescope').load_extension('fzf')
require('telescope').load_extension('dap')

-- require'telescope'.extensions.dap.commands{}
-- require'telescope'.extensions.dap.configurations{}
-- require'telescope'.extensions.dap.list_breakpoints{}
-- require'telescope'.extensions.dap.variables{}
-- require'telescope'.extensions.dap.frames{}