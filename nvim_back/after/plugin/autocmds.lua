local api = vim.api
local nkeymap = vim.api.nvim_set_keymap

local function FileFormatter()
  api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
      vim.schedule(xFileFormatter)
    end,
  })
  function xFileFormatter()
    local bufnr = api.nvim_get_current_buf()
    local ft = api.nvim_buf_get_option(bufnr, "filetype")
    -- if ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact" then
    --  nkeymap("n", "<leader>cf", ":CocCommand eslint.executeAutofix<CR>", {noremap = true})
    -- else 
    nkeymap("n", "<leader>cf", ":call CocActionAsync('format') <cr>", {noremap = true})
    -- end
  end
end

FileFormatter()

-- Highlight on yank
api.nvim_exec(
	[[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  augroup end
  ]],
	false
)

-- go to last loc when opening a buffer
api.nvim_create_autocmd(
  "BufReadPost",
  { command = [[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]] }
)

-- api.nvim_create_autocmd(
--   "User",
--   { 
--     command = [[CocJumpPlaceholder call CocActionAsync('showSignatureHelp') <cr>]] 
--   }
-- )

-- coc-highlight
api.nvim_create_autocmd(
  "CursorHold",
  {
    command = [[:silent call CocActionAsync('highlight')]] 
  }
)

