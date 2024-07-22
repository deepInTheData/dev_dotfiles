require("conform").setup {
  -- format_on_save = {
  --   timeout_ms = 2000,
  --   lsp_fallback = true,
  -- },
  -- formatters = {
  --   rubocop = {
  --     args = { "--server", "--auto-correct-all", "--stderr", "--force-exclusion", "--stdin", "$FILENAME" }
  --   }
  -- },
  formatters_by_ft = {
    lua = { "stylua" }, -- npm install -g stylua
    javascript = { "prettier" }, -- npm install -g prettier
    ruby = { "rubocop" }, -- gem install rubocop
    python = { 'isort', 'black' }, -- pip install isort black
    c = { "clang_format" }, -- brew install clang-format 
  },
}