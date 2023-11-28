local M = {}

local whichkey = require "which-key"

local next = next

local conf = {
  window = {
    border = "single", -- none, single, double, shadow
    position = "bottom", -- bottom, top
  },
}
whichkey.setup(conf)

local opts = {
  mode = "n", -- Normal mode
  prefix = "<leader>",
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = false, -- use `nowait` when creating keymaps
}

local v_opts = {
  mode = "v", -- Visual mode
  prefix = "<leader>",
  buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  silent = true, -- use `silent` when creating keymaps
  noremap = true, -- use `noremap` when creating keymaps
  nowait = false, -- use `nowait` when creating keymaps
}

local function normal_keymap()
  local keymap_f = nil -- File search
  local keymap_p = nil -- Project search

  keymap_f = {
    name = "Find",
    -- f = { "<cmd>lua require('utils.finder').find_files()<cr>", "Files" },
    -- d = { "<cmd>lua require('utils.finder').find_dotfiles()<cr>", "Dotfiles" },
    b = { "<cmd>lua require('telescope.builtin').buffers()<cr>", "Buffers" },
    h = { "<cmd>lua require('telescope.builtin').help_tags()<cr>", "Help" },
    m = { "<cmd>lua require('telescope.builtin').marks()<cr>", "Marks" },
    o = { "<cmd>lua require('telescope.builtin').oldfiles()<cr>", "Old Files" },
    c = { "<cmd>lua require('telescope.builtin').commands()<cr>", "Commands" },
    r = { "<cmd>lua require'telescope'.extensions.file_browser.file_browser()<cr>", "File Browser" },
  }

  local keymap = {
    ["w"] = { "<cmd>update!<CR>", "Save" },
    ["t"] = { "<cmd>ToggleTerm<CR>", "Terminal" },

    b = {
      name = "Buffer",
      c = { "<Cmd>BDelete this<Cr>", "Close Buffer" },
      f = { "<Cmd>BDelete! this<Cr>", "Force Close Buffer" },
      D = { "<Cmd>BWipeout other<Cr>", "Delete All Buffers" },
      b = { "<Cmd>BufferLinePick<Cr>", "Pick a Buffer" },
      p = { "<Cmd>BufferLinePickClose<Cr>", "Pick & Close a Buffer" },
      m = { "<Cmd>JABSOpen<Cr>", "Menu" },
    },

    c = {
      name = "Coc",
      -- navigate with <C-o> and <C-i>
      d = {"<Cmd>Telescope coc definitions<Cr>", "Go to definition"},
      D = {"<Cmd>Telescope coc declarations<Cr>", "Go to declaration"},
      i = {"<Cmd>Telescope coc implementations<Cr>", "Go to implementation"},
      t = {"<Cmd>Telescope coc type-definitions<Cr>", "Go to type definition"},
      R = {"<Plug>(coc-rename)", "Rename in current scope"},
      r = {"<Cmd>Telescope coc references<Cr>", "Code references"},
      o = {":call CocActionAsync('runCommand', 'editor.action.organizeImport') <CR>", "Organize imports"},
      e = {"<Cmd>Telescope coc diagnostics<Cr>", "Diagnostics"},
    },

    C = {
      name = "Code",
      g = { "<cmd>Neogen func<Cr>", "Func Doc" },
      G = { "<cmd>Neogen class<Cr>", "Class Doc" },
      d = { "<cmd>DogeGenerate<Cr>", "Generate Doc" },
      T = { "<cmd>TodoTelescope<Cr>", "TODO" },
      x = "Swap Next Param",
      X = "Swap Prev Param",
    },

    d = {
      name = "Debug",
    },

    -- Database
    D = {
      name = "Database",
      a = { "<Cmd>DBUIAddConnection<Cr>", "Add DB Connection" },
      u = { "<Cmd>DBUIToggle<Cr>", "Toggle UI" },
      f = { "<Cmd>DBUIFindBuffer<Cr>", "Find buffer" },
      r = { "<Cmd>DBUIRenameBuffer<Cr>", "Rename buffer" },
      q = { "<Cmd>DBUILastQueryInfo<Cr>", "Last query info" },
    },
    
    f = keymap_f,
    p = keymap_p,

    -- ThePrimeagen/harpoon
    j = {
      name = "Jump",
      a = { "<Cmd>lua require('harpoon.mark').add_file()<Cr>", "Add File" },
      m = { "<Cmd>lua require('harpoon.ui').toggle_quick_menu()<Cr>", "UI Menu" },
      c = { "<Cmd>lua require('harpoon.cmd-ui').toggle_quick_menu()<Cr>", "Command Menu" },
    },
    ["0"] = { "<Cmd>2ToggleTerm<Cr>", "ToggleTerm 2" },
    ["1"] = { "<Cmd>lua require('harpoon.ui').nav_file(1) <Cr>", "File 1" },
    ["2"] = { "<Cmd>lua require('harpoon.ui').nav_file(2) <Cr>", "File 2" },
    ["3"] = { "<Cmd>lua require('harpoon.ui').nav_file(3) <Cr>", "File 3" },
    ["4"] = { "<Cmd>lua require('harpoon.ui').nav_file(4) <Cr>", "File 4" },

    t = {
      name = "Neotest",
      a = { "<cmd>lua require('neotest').run.attach()<cr>", "Attach" },
      f = { "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>", "Run File" },
      F = { "<cmd>lua require('neotest').run.run({vim.fn.expand('%'), strategy = 'dap'})<cr>", "Debug File" },
      l = { "<cmd>lua require('neotest').run.run_last()<cr>", "Run Last" },
      L = { "<cmd>lua require('neotest').run.run_last({ strategy = 'dap' })<cr>", "Debug Last" },
      n = { "<cmd>lua require('neotest').run.run()<cr>", "Run Nearest" },
      N = { "<cmd>lua require('neotest').run.run({strategy = 'dap'})<cr>", "Debug Nearest" },
      o = { "<cmd>lua require('neotest').output.open({ enter = true })<cr>", "Output" },
      S = { "<cmd>lua require('neotest').run.stop()<cr>", "Stop" },
      s = { "<cmd>lua require('neotest').summary.toggle()<cr>", "Summary" },
    },

    r = {
      name = "Refactor",
      b = { [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Block')<CR>]], "Extract Block" },
      f = { [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Block To File')<CR>]], "Extract Block To File" },
      i = { [[ <Esc><Cmd>lua require('refactoring').refactor('Inline Variable')<CR>]], "Inline Variable" },
      p = { [[ <Esc><Cmd>lua require('refactoring').debug.printf({below = false})<CR>]], "Debug Print" },
      c = { [[ <Esc><Cmd>lua require('refactoring').debug.cleanup({below = false})<CR>]], "Debug Cleanup" },
    },

    z = {
      name = "System",
      s = { ":<C-u>SaveSession<Cr>", "Save session" },
      l = { ":<C-u>SearchSession<Cr>", "Load session" },
      c = { "<Cmd>Telescope colorscheme<Cr>", "Color scheme" },
      h = { "<Cmd>ToggleTerm<CR>", "New horizontal terminal" },
      t = { "<Cmd>terminal<CR>", "New terminal" },
      e = { "!!$SHELL<CR>", "Execute line" },
      r = { "<Cmd>luafile %<Cr>", "Reload lua file" },
      i = { "<Cmd>PackerUpdate<Cr>", "Packer update" }
    },    


    -- Stand alone commands prefixed with <leader>
    ["<C-f>"] = { "<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<cr>", "Current Buffer" },
    ["["] = { "<Plug>(coc-diagnostic-prev)", "<- diagnostic"  },
    ["]"] = { "<Plug>(coc-diagnostic-next)", "-> diagnostic"  },

      -- x = { "<cmd>cd %:p:h<cr>", "Change Directory" },
      -- x = { "<cmd>set autochdir<cr>", "Auto ChDir" },
  }
  whichkey.register(keymap, opts)
end

-- TODO: Choose between this or built in coc-refactor
local function visual_keymap()
  local keymap = {
    -- "ThePrimeagen/refactoring.nvim"
    r = {
      name = "Refactor",
      e = { [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Function')<CR>]], "Extract Function" },
      f = { [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Function To File')<CR>]] , "Extract Function to File" },
      v = { [[ <Esc><Cmd>lua require('refactoring').refactor('Extract Variable')<CR>]], "Extract Variable" },
      i = { [[ <Esc><Cmd>lua require('refactoring').refactor('Inline Variable')<CR>]], "Inline Variable" },
      r = { [[ <Esc><Cmd>lua require('telescope').extensions.refactoring.refactors()<CR>]], "Refactor Menu" },
      V = { [[ <Esc><Cmd>lua require('refactoring').debug.print_var({})<CR>]], "Debug Print Var" },
    },
  }

  whichkey.register(keymap, v_opts)
end

local function code_keymap()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
      vim.schedule(CodeRunner)
    end,
  })

  function CodeRunner()
    local bufnr = vim.api.nvim_get_current_buf()
    local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
    local fname = vim.fn.expand "%:p:t"
    local keymap_C = {} -- normal key map
    local keymap_C_v = {} -- visual key map

    if ft == "python" then
      keymap_C = {
        name = "Code",
        r = { "<cmd>update<CR><cmd>exec '!python3' shellescape(@%, 1)<cr>", "Run" },
        m = { "<cmd>TermExec cmd='nodemon -e py %'<cr>", "Monitor" },
      }
    elseif ft == "lua" then
      keymap_C = {
        name = "Code",
        r = { "<cmd>luafile %<cr>", "Run" },
      }
    elseif ft == "go" then
      keymap_C = {
        name = "Code",
        r = { "<cmd>GoRun<cr>", "Run" },
      }
    elseif ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact" then
      keymap_C = {
        name = "Code",
        o = { "<cmd>TypescriptOrganizeImports<cr>", "Organize Imports" },
        r = { "<cmd>TypescriptRenameFile<cr>", "Rename File" },
        i = { "<cmd>TypescriptAddMissingImports<cr>", "Import Missing" },
        F = { "<cmd>TypescriptFixAll<cr>", "Fix All" },
        u = { "<cmd>TypescriptRemoveUnused<cr>", "Remove Unused" },
        R = { "<cmd>lua require('config.test').javascript_runner()<cr>", "Choose Test Runner" },
        -- s = { "<cmd>2TermExec cmd='yarn start'<cr>", "Yarn Start" },
        -- t = { "<cmd>2TermExec cmd='yarn test'<cr>", "Yarn Test" },
      }
    end

    if fname == "package.json" then
      keymap_C.v = { "<cmd>lua require('package-info').show()<cr>", "Show Version" }
      keymap_C.c = { "<cmd>lua require('package-info').change_version()<cr>", "Change Version" }
      -- keymap_c.s = { "<cmd>2TermExec cmd='yarn start'<cr>", "Yarn Start" }
      -- keymap_c.t = { "<cmd>2TermExec cmd='yarn test'<cr>", "Yarn Test" }
    end

    if next(keymap_C) ~= nil then
      local k = { C = keymap_C }
      local o = { mode = "n", silent = true, noremap = true, buffer = bufnr, prefix = "<leader>", nowait = true }
      whichkey.register(k, o)
    end

    if next(keymap_C_v) ~= nil then
      local k = { C = keymap_C_v }
      local o = { mode = "v", silent = true, noremap = true, buffer = bufnr, prefix = "<leader>", nowait = true }
      whichkey.register(k, o)
    end
  end
end

function M.setup()
  normal_keymap()
  visual_keymap()
  code_keymap()
end

return M
