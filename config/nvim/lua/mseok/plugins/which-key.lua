local function open_netrw_at_vimrcdir()
  local vimrc_dir = vim.fn.fnamemodify(vim.fn.getenv("MYVIMRC"), ":p:h")
  vim.cmd("Ex " .. vimrc_dir)
  vim.cmd("cd " .. vimrc_dir)
end

return {
  "folke/which-key.nvim",

  event = "VeryLazy",

  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,

  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    preset = "helix",
  },

  config = function()
    local wk = require("which-key")
    
    -- Don't register these keymaps in VS Code - they may conflict
    if not vim.g.vscode then
      wk.add({
        -- Terminal
        { "<leader>c", group = "code" },
        { "<leader>ct", "<cmd>vsplit term://$SHELL<CR>", desc = "new terminal" },
        { "<leader>cp", "<cmd>vsplit term://python<CR>", desc = "new python terminal" },

        -- Telescope
        { "<leader>f", group = "Find (telescope)" },
        { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "files" },
        { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "help" },
        { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "keymaps" },
        { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "old files" },
        { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "grep" },
        { "<leader>fb", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "fuzzy" },
        { "<leader>fm", "<cmd>Telescope marks<CR>", desc = "marks" },
        { "<leader>fM", "<cmd>Telescope man_pages<CR>", desc = "man pages" },
        { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "symbols" },
        { "<leader>fd", "<cmd>Telescope buffers<CR>", desc = "buffers" },
        { "<leader>fq", "<cmd>Telescope quickfix<CR>", desc = "quickfix" },
        { "<leader>fl", "<cmd>Telescope loclist<CR>", desc = "loclist" },
        { "<leader>fj", "<cmd>Telescope jumplist<CR>", desc = "marks" },

        -- Vim
        { "<leader>v", group = "Vim" },
        { "<leader>vt", toggle_light_dark_theme, desc = "switch theme" },
        { "<leader>vc", "<cmd>Telescope colorscheme<CR>", desc = "colortheme" },
        { "<leader>vl", "<cmd>Lazy<CR>", desc = "Lazy" },
        { "<leader>vm", "<cmd>Mason<CR>", desc = "Mason" },
        { "<leader>vs", open_netrw_at_vimrcdir, desc = "Settings" },
        { "<leader>vh", '<cmd>execute "h " .. expand("<cword>")<CR>', desc = "help" },
      })
    else
      -- VS Code-specific keymaps could be added here
      wk.add({
        -- Add VS Code-specific keymaps if needed
      })
    end
  end,
}
