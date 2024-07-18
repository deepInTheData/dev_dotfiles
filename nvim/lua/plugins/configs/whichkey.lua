local whichkey = require "which-key"

whichkey.add({
  { "<leader>g", group = "git" }, -- group
  { "<leader>/", desc = "Toogle Comments" }, -- gcc

  { "<leader>f", group = "file" }, -- group
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
  { "<leader>fm", desc = "Format File", mode = "n" },
  { "<leader>f\\", "<cmd>Telescope live_grep<cr>", desc = "Grep", mode = "n" },
  { "<leader>b", group = "buffers", expand = function()
      return require("which-key.extras").expand.buf()
    end
  },
  {
    -- Nested mappings are allowed and can be added in any order
    -- Most attributes can be inherited or overridden on any level
    -- There's no limit to the depth of nesting
    mode = { "n", "v" }, -- NORMAL and VISUAL mode
    { "<leader>q", "<cmd>q<cr>", desc = "Quit" }, -- no need to specify mode since it's inherited
    { "<leader>w", "<cmd>w<cr>", desc = "Write" },
  }
})
