local whichkey = require "which-key"

local function get_git_refs()
  -- Get local branches
  local local_branches = vim.fn.systemlist("git branch --format='%(refname:short)'")
  
  -- Get remote branches
  local remote_branches = vim.fn.systemlist("git branch -r --format='%(refname:short)'")
  
  -- Get tags
  local tags = vim.fn.systemlist("git tag")
  
  local refs = {}
  
  -- Add local branches
  for _, branch in ipairs(local_branches) do
    table.insert(refs, branch)
  end
  
  -- Add remote branches
  for _, branch in ipairs(remote_branches) do
    table.insert(refs, branch)
  end
  
  -- Add tags with prefix for clarity
  for _, tag in ipairs(tags) do
    table.insert(refs, "tags/" .. tag)
  end
  
  return refs
end

-- Telescope picker for git refs
local function create_ref_picker()
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  
  return function(opts, callback)
    opts = opts or {}
    pickers.new(opts, {
      prompt_title = "Git References",
      finder = finders.new_table {
        results = get_git_refs()
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          callback(selection[1])
        end)
        return true
      end,
    }):find()
  end
end

-- Make the function available to vim globally for completion
_G.git_refs = function()
  return get_git_refs()
end

whichkey.setup({
  layout = {
    height = { min = 4, max = 25 },
    width = { min = 20, max = 50 },
    spacing = 3,
    align = "left",
  }  
})


whichkey.add({
  { "<leader>g", group = "git" }, -- git group
  { "<leader>gd",
    function()
      local current_branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("%s+", "")
      
      -- Use Telescope for reference selection
      local pick_ref = create_ref_picker()
      
      pick_ref({}, function(base_ref)
        if base_ref == nil then return end
        
        pick_ref({}, function(compare_ref)
          if compare_ref == nil then return end
          
          -- Remove 'tags/' prefix if present for the DiffviewOpen command
          base_ref = base_ref:gsub("^tags/", "")
          compare_ref = compare_ref:gsub("^tags/", "")
          
          -- Open diffview with the selected references
          vim.cmd(string.format(":DiffviewOpen %s...%s", base_ref, compare_ref))
        end)
      end)
    end,
    desc = "Compare git references (branches/tags)"
  },
  
  -- Add a keybinding to quickly show all references
  { "<leader>gr",
    function()
      local refs = get_git_refs()
      -- Create a temporary buffer to display refs
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Local Branches:",
        "----------------",
        unpack(vim.fn.systemlist("git branch --format='  %(refname:short)'")),
        "",
        "Remote Branches:",
        "----------------",
        unpack(vim.fn.systemlist("git branch -r --format='  %(refname:short)'")),
        "",
        "Tags:",
        "-----",
        unpack(vim.tbl_map(function(tag) return "  " .. tag end, vim.fn.systemlist("git tag")))
      })
      
      -- Open in a floating window
      local width = 60
      local height = 20
      local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2,
        style = 'minimal',
        border = 'rounded'
      })
      
      -- Set buffer options
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
      vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
      vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', {noremap = true, silent = true})
    end,
    desc = "Show all git references"
  },
  { "<leader>gf",
      "<CMD>:DiffviewFileHistory %<CR>",
      desc = "Git current file history"
  },
  { "<leader>gt", "<CMD>:DiffviewToggleFiles<CR>", desc = "Toogle File Panel"},

  
  { "<leader>/", desc = "Toogle Comments" }, -- gcc
  { "<leader><C-n>", desc = "Toogle Tree" }, -- nvimtree
  { "<leader>T", "<cmd>Lspsaga term_toggle<cr>", desc = "Toogle Tree" }, -- nvimtree
  

  { "<leader>c", group = "code" }, -- code group
  { "<leader>cD", vim.lsp.buf.declaration, desc = "Go to Declaration", mode = "n" },
  { "<leader>cd", vim.lsp.buf.definition, desc = "Go to Definition", mode = "n" },
  { "<leader>cK", vim.lsp.buf.hover, desc = "Hover Information", mode = "n" },
  { "<leader>ci", vim.lsp.buf.implementation, desc = "Go to Implementation", mode = "n" },
  { "<leader>ck", vim.lsp.buf.signature_help, desc = "Signature Help", mode = "n" },
  { "<leader>co", "<cmd>Lspsaga outline<cr>", desc = "Signature Help", mode = "n" },
  
  { "<leader>cwa", vim.lsp.buf.add_workspace_folder, desc = "Add Workspace Folder", mode = "n" },
  { "<leader>cwr", vim.lsp.buf.remove_workspace_folder, desc = "Remove Workspace Folder", mode = "n" },
  { "<leader>cwl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, desc = "List Workspace Folders", mode = "n" },
  { "<leader>cT", vim.lsp.buf.type_definition, desc = "Type Definition", mode = "n" },
  { "<leader>cR", vim.lsp.buf.rename, desc = "Rename", mode = "n" },
  { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "v" } },
  -- { "<leader>cr", vim.lsp.buf.references, desc = "References", mode = "n" },
  { "<leader>cr", "<cmd>Lspsaga finder<cr>", desc = "References", mode = "n" },

  { "<leader>t", group = "tests" }, -- tests group
  { "<leader>tn", "<CMD>:TestNearest<CR>", desc = "Run NEAREST test and toggle summary", mode = "n" },
  { "<leader>ta", '<CMD>:TestFile<CR>', desc = "Run ALL test", mode = "n" },
  { "<leader>tl", '<CMD>:TestLast<CR>', desc = "run LAST test", mode = "n" },

  -- { "<leader>tn", "<CMD>lua require('neotest').run.run()<CR><BAR><CMD>lua require('neotest').summary.open()<CR>", desc = "Run NEAREST test and toggle summary", mode = "n" },
  -- { "<leader>ta", '<CMD>lua require("neotest").run.run(vim.fn.expand("%"))<CR><BAR><CMD>lua require("neotest").summary.open()<CR>', desc = "Run ALL test", mode = "n" },
  -- { "<leader>tl", '<CMD>lua require("neotest").run.run_last()<CR>', desc = "run LAST test", mode = "n" },
  
  { "<leader>td", '<CMD>lua require("neotest").run.run({strategy = "dap"})<CR>', desc = "DEBUG nearest test", mode = "n" },
  { "<leader>ts", '<CMD>lua require("neotest").summary.toggle()<CR>', desc = "Toogle SUMMARY", mode = "n" },
  { "<leader>tw", '<CMD>lua require("neotest").watch.toggle(vim.fn.expand("%"))<CR>', desc = "Toogle WATCH", mode = "n" },
  { "<leader>t[", '<CMD>lua require("neotest").jump.prev({ status = "failed" })<CR>', desc = "Previous FAILED", mode = "n" },
  { "<leader>t]", '<CMD>lua require("neotest").jump.next({ status = "failed" })<CR>', desc = "Next FAILED", mode = "n" },
  
  { "<leader>d", group = "Debug" }, -- Debug group
  -- <cmd> lua require('dapui').open({reset = true})<CR>
  { "<leader>dr", group = "Debug Restart" }, -- Debug group
  { "<leader>drr", "<cmd>lua require'dap'.restart()<cr>", desc = "Restart debugger", mode = "n" },
  { "<leader>drf", "<cmd>lua require'dap'.restart_frame()<cr>", desc = "Restart frame", mode = "n" },

  { "<leader>dc", "<cmd>lua require'dap'.continue()<cr>", desc = "Continue", mode = "n" },
  { "<leader>dC", "<cmd>lua require'dap'.set_breakpoint(vim.fn.input '[Condition] > ')<cr>", desc = "Conditional Breakpoint", mode = "n" },
  { "<leader>dd", "<cmd>lua require'dap'.focus_frame()<cr>", desc = "Focus current frame", mode = "n" },
  { "<leader>de", "<cmd>lua require'dapui'.eval()<cr>", desc = "Evaluate", mode = "n" },
  { "<leader>di", "<cmd>lua require'dap'.step_into()<cr>", desc = "Step Into", mode = "n" },
  { "<leader>do", "<cmd>lua require'dap'.step_over()<cr>", desc = "Step Over", mode = "n" },
  { "<leader>dO", "<cmd>lua require'dap'.step_out()<cr>", desc = "Step Out", mode = "n" },

  { "<leader>dj", "<cmd>lua require'dap'.up()<cr>", desc = "Go up the stack frame", mode = "n" },
  { "<leader>dk", "<cmd>lua require'dap'.down()<cr>", desc = "Go down the stack frame", mode = "n" },
  { "<leader>dt", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", desc = "Toggle Breakpoint", mode = "n" },
  { "<leader>dx", "<cmd>lua require'dap'.terminate()<cr>", desc = "Terminate", mode = "n" },
  { "<leader>dh", "<cmd>lua require'dap.ui.widgets'.hover()<cr>", desc = "Hover Variables", mode = "n" },

  -- DAP UI telescope
  { "<leader>db", "<cmd>Telescope dap list_breakpoints<cr>", desc = "Telescope list breakpoints", mode = "n" },
  { "<leader>df", "<cmd>Telescope dap frames<cr>", desc = "Telescope Stack Trace", mode = "n" },
  { "<leader>dR", "<cmd>lua require('dapui').float_element('repl', { width = 100, height = 20, enter = true, position = 'center' })<cr>", desc = "Telescope Toogle Repl", mode = "n" },
  { "<leader>dw", "<cmd>lua require('dapui').float_element('watches', { width = 100, height = 20, enter = true, position = 'bottom' })<cr>", desc = "Telescope Toogle Watch", mode = "n" },
  { "<leader>du", "<cmd>lua require'dapui'.toggle()<cr>", desc = "Telescope DAP UI", mode = "n" },

  -- DAP variables 
  { "<leader>dv", "<cmd>lua require'telescope'.extensions.dap.variables{}<cr>", desc = "View variables", mode = "n" },

  { "<leader>f", group = "file" }, -- file group
  { "<leader>ff", "<CMD>Telescope find_files<cr>", desc = "Find File", mode = "n" },
  { "<leader>fm", desc = "Format File", mode = "n" },
  { "<leader>f\\", "<CMD>Telescope live_grep<cr>", desc = "Grep", mode = "n" },

  
  { "<leader>b", group = "buffers", expand = function()
      return require("which-key.extras").expand.buf()
    end
  },
  { "<leader>b<Tab>", "<cmd> BufferLineCycleNext <CR>", desc = "next buffer", mode = "n" },
  { "<leader>b<S-Tab>", "<cmd> BufferLineCyclePrev <CR>", desc = "previous buffer", mode = "n" },
  { "<leader>b<C-w>", "<cmd> bd <CR>", desc = "buffer delete", mode = "n" },
})


