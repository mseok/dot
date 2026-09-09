local map = vim.keymap.set

local treesitter_languages = { "python", "bash", "lua", "vim", "vimdoc", "query" }
local treesitter_filetypes = { "python", "bash", "sh", "lua", "vim", "vimdoc", "query" }

local treesitter_textobjects = {
  ["af"] = "@function.outer",
  ["if"] = "@function.inner",
  ["ac"] = "@class.outer",
  ["ic"] = "@class.inner",
  ["al"] = "@loop.outer",
  ["il"] = "@loop.inner",
  ["aa"] = "@parameter.outer",
  ["ia"] = "@parameter.inner",
  ["ai"] = "@conditional.outer",
  ["ii"] = "@conditional.inner",
  ["ab"] = "@block.outer",
  ["ib"] = "@block.inner",
  ["acm"] = "@comment.outer",
}

local function start_treesitter(bufnr)
  local ok, err = pcall(vim.treesitter.start, bufnr)
  if not ok and not tostring(err):match("No parser") then
    vim.notify("Tree-sitter could not start: " .. tostring(err), vim.log.levels.WARN)
  end
end

-- nvim-treesitter/main is a Neovim 0.12+ rewrite. Keep a small fallback so
-- an already-running session can reload this config before its next restart,
-- while the normal path uses the current upstream API.
local has_new_treesitter = pcall(require, "nvim-treesitter.config")
if has_new_treesitter then
  local treesitter = require("nvim-treesitter")
  treesitter.setup({
    install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
  })

  local treesitter_group = vim.api.nvim_create_augroup("dot_treesitter", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = treesitter_group,
    pattern = treesitter_filetypes,
    callback = function(args)
      start_treesitter(args.buf)
    end,
  })

  local ok_textobjects, textobjects = pcall(require, "nvim-treesitter-textobjects")
  local ok_select, select = pcall(require, "nvim-treesitter-textobjects.select")
  if ok_textobjects and ok_select then
    textobjects.setup({
      select = { lookahead = true },
    })

    for lhs, query in pairs(treesitter_textobjects) do
      map({ "x", "o" }, lhs, function()
        select.select_textobject(query, "textobjects")
      end, { desc = "Select Tree-sitter " .. query })
    end
  end

  -- Install only the small language set used by this config. This is
  -- asynchronous and therefore does not block an SSH login; set
  -- DOT_TS_AUTO_INSTALL=0 on a cluster where parser downloads are disallowed.
  if vim.env.DOT_TS_AUTO_INSTALL ~= "0" then
    vim.schedule(function()
      local installed = {}
      for _, language in ipairs(treesitter.get_installed("parsers")) do
        installed[language] = true
      end

      local missing = vim.tbl_filter(function(language)
        return not installed[language]
      end, treesitter_languages)
      if #missing > 0 then
        local ok, task = pcall(treesitter.install, missing)
        if not ok then
          vim.notify("Tree-sitter parser install failed: " .. tostring(task), vim.log.levels.WARN)
        end
      end
    end)
  end
else
  -- Compatibility path for an older nvim-treesitter checkout. It is only
  -- used during a transition; the managed branch above is the supported one.
  local ok, configs = pcall(require, "nvim-treesitter.configs")
  if ok then
    configs.setup({
      ensure_installed = treesitter_languages,
      highlight = { enable = true },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = treesitter_textobjects,
        },
      },
    })
  else
    vim.schedule(function()
      vim.notify("Tree-sitter is unavailable: install nvim-treesitter.", vim.log.levels.WARN)
    end)
  end
end

-- nvim-tree file explorer
require("nvim-tree").setup({
  disable_netrw = true,
  hijack_netrw = true,
  view = {
    width = 36,
    side = "left",
  },
  renderer = {
    highlight_git = true,
    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
      },
    },
  },
  filters = {
    dotfiles = false,
  },
  git = {
    enable = true,
    ignore = false,
  },
  update_focused_file = {
    enable = true,
  },
})
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>")
vim.cmd("autocmd VimEnter * hi NvimTreeNormal guibg=NONE" )
vim.cmd("autocmd VimEnter * hi NvimTreeNormalNC guibg=NONE" )

-- Telescope
local telescope = require("telescope")
telescope.setup({
  defaults = {
    preview = { treesitter = false },
    color_devicons = true,
    sorting_strategy = "ascending",
    borderchars = {
      "─", -- top
      "│", -- right
      "─", -- bottom
      "│", -- left
      "┌", -- top-left
      "┐", -- top-right
      "┘", -- bottom-right
      "└", -- bottom-left
    },
    path_displays = { "smart" },
    layout_config = {
      height = 0.9,
      width = 0.9,
      prompt_position = "top",
      preview_cutoff = 40,
    }
  }
})

-- Telescope keymaps
local builtin = require("telescope.builtin")

map("n", "<leader>ff", builtin.find_files)
map("n", "<leader>fr", builtin.oldfiles)
map("n", "<leader>fh", builtin.help_tags)
map("n", "<leader>fm", builtin.man_pages)
map("n", "<leader>fg", builtin.live_grep)
map("n", "<leader>fb", builtin.buffers)
map("n", "<leader>r", builtin.registers)

map("n", "<leader>x", "<cmd>lua vim.diagnostic.setloclist()<CR>")

-- Marks
require("marks").setup {
  builtin_marks = {},
  refresh_interval = 250,
  sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
  excluded_filetypes = {},
  excluded_buftypes = {},
  mappings = {}
}
vim.keymap.set("n", "ma", "<cmd>MarksListAll<CR>")

-- Mini.pairs
require('mini.pairs').setup()
