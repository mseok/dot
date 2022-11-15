local action_layout = require("telescope.actions.layout")
local previewers = require("telescope.previewers")

require("telescope").setup{
  defaults = {
    file_previewer = previewers.vim_buffer_cat.new,
    grep_previewer = previewers.vim_buffer_vimgrep.new,
    qflist_previewer = previewers.vim_buffer_qflist.new,
    buffer_previewer_maker = previewers.buffer_previewer_maker,
    file_ignore_patterns = {".git"},
    mappings = {
      i = {
        ["<C-h>"] = "select_horizontal",
        ["<C-j>"] = "move_selection_next",
        ["<C-k>"] = "move_selection_previous",
        ["?"] = action_layout.toggle_preview,
      },
      n = {
        ["<C-c>"] = "close"
      }
    }
  },
  pickers = {
    git_files = {
      theme = "dropdown",
    },
    find_files = {
      theme = "dropdown",
    },
    grep_string = {
      theme = "dropdown",
    },
    live_grep = {
      theme = "dropdown",
    },
  },
}
