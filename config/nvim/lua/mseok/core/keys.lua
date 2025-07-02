local function tree()
  local node = vim.treesitter.get_node()
  local i = 0
  while true do
    print(node:type())
    if node:type() ~= "code" then
      node = node:parent()
    else
      break
    end

    if i < 10 then
      break
    end
    i = i + 1
  end

  if not node then
    print("No node found")
    return
  end

  local start_row, start_col, end_row, end_col = node:range()

  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  vim.cmd("normal! v") -- start visual mode
  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col - 1 })
end

vim.keymap.set({ "n", "v" }, "<leader>o", tree, {})
