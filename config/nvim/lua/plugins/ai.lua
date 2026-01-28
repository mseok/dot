vim.g.sidekick_nes = true
vim.b.sidekick_nes = true

-- Sidekick setup
require("sidekick").setup({
  nes = {
    ---@type boolean|fun(buf:integer):boolean?
    enabled = function(buf)
      return vim.g.sidekick_nes ~= false and vim.b.sidekick_nes ~= false
    end,
  }
})

-- Sidekick keymaps
local cli = require("sidekick.cli")
vim.keymap.set("n", "<leader>aa", cli.toggle, { desc = "Sidekick Toggle" })
vim.keymap.set("n", "<leader>as", cli.select, { desc = "Sidekick Select" })
vim.keymap.set("n", "<leader>ad", cli.close, { desc = "Sidekick Close" })
vim.keymap.set({ "n", "x" }, "<leader>at", function()
  cli.send({ msg = "{this}" })
end, { desc = "Sidekick Send This" })
vim.keymap.set("n", "<leader>af", function()
  cli.send({ msg = "{file}" })
end, { desc = "Sidekick Send File" })
vim.keymap.set("x", "<leader>av", function()
  cli.send({ msg = "{selection}" })
end, { desc = "Sidekick Send Selection" })
vim.keymap.set("n", "<leader>ap", cli.prompt, { desc = "Sidekick Prompt" })
vim.keymap.set({ "n", "x", "i", "t" }, "<C-.>", cli.toggle, { desc = "Sidekick Toggle" })

-- Normal mode: use <Tab> for Sidekick NES jump/apply, otherwise keep normal <Tab>
vim.keymap.set("n", "<Tab>", function()
  if require("sidekick").nes_jump_or_apply() then
    return ""
  end
  return "<Tab>"
end, { expr = true, desc = "Sidekick NES jump/apply (normal)" })
