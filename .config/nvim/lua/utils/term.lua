local M = {}

local Terminal = require("toggleterm.terminal").Terminal

-- Open a terminal
local function default_on_open(term)
  vim.cmd "stopinsert"
  vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
end

function M.open_term(cmd, opts)
  opts = opts or {}
  local winheight = vim.fn.winheight(0)
  opts.size = opts.size or winheight * 0.25
  opts.direction = opts.direction or "horizontal"
  opts.on_open = opts.on_open or default_on_open
  opts.on_exit = opts.on_exit or nil

  local new_term = Terminal:new {
    cmd = cmd,
    auto_scroll = false,
    close_on_exit = false,
    start_in_insert = true,
    on_open = opts.on_open,
    on_exit = opts.on_exit,
  }
  new_term:open(opts.size, opts.direction)
end

return M
