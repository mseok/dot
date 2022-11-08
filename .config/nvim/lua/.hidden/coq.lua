if vim.fn.has('python3') then
  vim.g.coq_settings = {
    ["auto_start"] = 'shut-up',
    ["keymap.recommended"] = false,
    clients = {
      lsp = {
        enabled = true,
        resolve_timeout = 0.25,
      },
      paths = {
        enabled = true,
        resolution = { "cwd", "file" },
      },
      snippets = { enabled = false },
      buffers = { enabled = true },
      tags = { enabled = false },
      tmux = { enabled = false },
      tree_sitter = { enabled = false },
    },
    limits = {
      idle_timeout = 0.1,
      completion_auto_timeout = 0.1,
      -- completion_manual_timeout = 0.7,
    },
    display = {
      icons = { mode = 'short' },
      ghost_text = { enabled = false },
    },
  }

  require("coq") {}
end
