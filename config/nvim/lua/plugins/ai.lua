-- Copilot setup - disable ghost text suggestion (use blink-cmp-copilot instead)
require("copilot").setup({
  copilot_node_command = vim.fn.exepath("node"),
  panel = { enabled = false },
  suggestion = { enabled = false }, -- Disabled: using blink-cmp-copilot instead
  filetypes = {
    ["*"] = true,
  },
})

-- opencode.nvim setup
vim.o.autoread = true -- Required for buffer reload when opencode edits files

---@type opencode.Opts
vim.g.opencode_opts = {
  provider = {
    enabled = "tmux", -- Options: "terminal", "tmux", "wezterm"
    terminal = {},
    tmux = {},
    wezterm = {},
  },
}

-- opencode keybindings with <leader>o prefix
vim.keymap.set({ "n", "x" }, "<leader>oa", function()
  require("opencode").ask("@this: ", { submit = true })
end, { desc = "Ask opencode" })

vim.keymap.set({ "n", "x" }, "<leader>os", function()
  require("opencode").select()
end, { desc = "Select opencode action" })

vim.keymap.set({ "n", "t" }, "<leader>ot", function()
  require("opencode").toggle()
end, { desc = "Toggle opencode" })

vim.keymap.set({ "n", "x" }, "<leader>op", function()
  return require("opencode").operator("@this ")
end, { expr = true, desc = "Add range to opencode" })

vim.keymap.set("n", "<leader>ou", function()
  require("opencode").command("session.half.page.up")
end, { desc = "opencode scroll up" })

vim.keymap.set("n", "<leader>od", function()
  require("opencode").command("session.half.page.down")
end, { desc = "opencode scroll down" })

vim.keymap.set("n", "<leader>on", function()
  require("opencode").command("session.new")
end, { desc = "New opencode session" })

vim.keymap.set("n", "<leader>oi", function()
  require("opencode").command("session.interrupt")
end, { desc = "Interrupt opencode" })

-- Provider switcher
vim.keymap.set("n", "<leader>oP", function()
  vim.ui.select({ "terminal", "tmux", "wezterm" }, {
    prompt = "Select opencode provider:",
  }, function(choice)
    if choice then
      vim.g.opencode_opts.provider.enabled = choice
      vim.notify("opencode provider: " .. choice)
    end
  end)
end, { desc = "Select opencode provider" })
