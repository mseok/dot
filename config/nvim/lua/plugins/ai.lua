require("copilot").setup({
  copilot_node_command = vim.fn.exepath("node"),
  panel = {
    enabled = false,
  },
  suggestion = {
    enabled = true,
    auto_trigger = true,
    hide_during_completion = false,
    keymap = {
      accept = false,    -- accept ghost text
      next = "<M-]>",    -- cycle ghost suggestions
      prev = "<M-[>",
      dismiss = "<C-]>", -- dismiss ghost
    },
  },
  filetypes = {
    ["*"] = true, -- enable for all filetypes
  },
})

require("sidekick").setup({
  nes = {
    ---@type boolean|fun(buf:integer):boolean?
    enabled = true,
  },
  -- Work with AI cli tools directly from within Neovim
  cli = {
    watch = true, -- notify Neovim of file changes done by AI CLI tools
    ---@class sidekick.win.Opts
    win = {
      ---@type table<string, sidekick.cli.Keymap|false>
      keys = {
        buffers       = { "<c-b>", "buffers", mode = "nt", desc = "open buffer picker" },
        files         = { "<c-f>", "files", mode = "nt", desc = "open file picker" },
        hide_n        = { "q", "hide", mode = "n", desc = "hide the terminal window" },
        hide_ctrl_q   = { "<c-q>", "hide", mode = "n", desc = "hide the terminal window" },
        hide_ctrl_dot = { "<c-.>", "hide", mode = "nt", desc = "hide the terminal window" },
        hide_ctrl_z   = { "<c-z>", "hide", mode = "nt", desc = "hide the terminal window" },
        prompt        = { "<c-p>", "prompt", mode = "t", desc = "insert prompt or context" },
        stopinsert    = { "<c-q>", "stopinsert", mode = "t", desc = "enter normal mode" },
        -- Navigate windows in terminal mode. Only active when:
        -- * layout is not "float"
        -- * there is another window in the direction
        -- With the default layout of "right", only `<c-h>` will be mapped
        nav_left      = { "<c-h>", "nav_left", expr = true, desc = "navigate to the left window" },
        nav_down      = { "<c-j>", "nav_down", expr = true, desc = "navigate to the below window" },
        nav_up        = { "<c-k>", "nav_up", expr = true, desc = "navigate to the above window" },
        nav_right     = { "<c-l>", "nav_right", expr = true, desc = "navigate to the right window" },
      },
      ---@type fun(dir:"h"|"j"|"k"|"l")?
      --- Function that handles navigation between windows.
      --- Defaults to `vim.cmd.wincmd`. Used by the `nav_*` keymaps.
      nav = nil,
    },
    ---@type table<string, sidekick.cli.Config|{}>
    tools = {
      claude = { cmd = { "claude" } },
      codex = { cmd = { "codex", "--search" } },
      copilot = { cmd = { "copilot", "--banner" } },
      gemini = { cmd = { "gemini" } },
    },
    ---@type table<string, sidekick.Prompt|string|fun(ctx:sidekick.context.ctx):(string?)>
    prompts = {
      changes         = "Can you review my changes?",
      diagnostics     = "Can you help me fix the diagnostics in {file}?\n{diagnostics}",
      diagnostics_all = "Can you help me fix these diagnostics?\n{diagnostics_all}",
      document        = "Add documentation to {function|line}",
      explain         = "Explain {this}",
      fix             = "Can you fix {this}?",
      optimize        = "How can {this} be optimized?",
      review          = "Can you review {file} for any issues or improvements?",
      tests           = "Can you write tests for {this}?",
      -- simple context prompts
      buffers         = "{buffers}",
      file            = "{file}",
      line            = "{line}",
      position        = "{position}",
      quickfix        = "{quickfix}",
      selection       = "{selection}",
      ["function"]    = "{function}",
      class           = "{class}",
    },
    -- preferred picker for selecting files
    ---@alias sidekick.picker "snacks"|"telescope"|"fzf-lua"
    picker = "telescope", ---@type sidekick.picker
  },
})

-- Tab keymap for Next Edit Suggestions in normal mode
vim.keymap.set("n", "<Tab>", function()
  -- if there is a next edit, jump to it, otherwise apply it if any
  if require("sidekick").nes_jump_or_apply() then
    return -- jumped or applied
  end
  -- fall back to normal tab
  return "<Tab>"
end, { expr = true, desc = "Goto/Apply Next Edit Suggestion" })
