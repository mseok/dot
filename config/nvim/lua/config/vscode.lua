local M = {}

local keymap = vim.keymap.set

local opts = { silent = true }
local function opts_desc(desc, callback)
	return {
		silent = true,
		desc = desc,
		callback = callback,
	}
end

vim.filetype.add({
	pattern = {
		[".*%.ipynb.*"] = "python",
		-- uses lua pattern matching
		-- rathen than naive matching
	},
})

vim.o.cmdheight = 1

local function code_do(cmd)
	return string.format("<cmd>lua require'vscode'.action('%s')<CR>", cmd)
end

-- LSP related keymaps
keymap("n", "grr", code_do("editor.action.goToReferences"), opts)
keymap("n", "gd", code_do("editor.action.goToTypeDefinition"), opts)
keymap("n", "grn", code_do("editor.action.rename"), opts)
keymap("n", "gra", code_do("editor.action.quickFix"), opts)
keymap("n", "grf", code_do("editor.action.formatDocument"), opts)
-- In Normal mode, map 'K' to show the hover pop-up without stealing focus.
vim.keymap.set("n", "K", function()
	-- Call the VSCode 'showHover' action with the { focus = false } argument.
	require("vscode").action("editor.action.showHover", { focus = false })
end, { noremap = true, silent = true, desc = "Show hover without focus" })

-- extension related keymaps
keymap("n", "<Leader>xu", code_do("workbench.extensions.action.updateAllExtensions"), opts) -- update all extensions

-- search/find related keymaps
keymap("n", "<Leader>fr", code_do("workbench.action.openRecent"), opts)
keymap("n", "<Leader>fw", code_do("workbench.action.findInFiles"), opts)
keymap("n", "<Leader>ff", code_do("workbench.action.quickOpen"), opts)

-- TODO: check this needed
keymap("n", "<Leader>ta", code_do("composer.newAgentChat"), opts)
keymap("n", "<Leader>tx", code_do("workbench.view.extensions"), opts) -- show extensions

-- switch focus keymaps
keymap("n", "<Leader>ss", code_do("workbench.action.focusSideBar"), opts) -- switch to sidebar
keymap("n", "<Leader>sp", code_do("workbench.action.focusPanel"), opts) -- switch to panel

-- in vim, a tab contains multiple windows
-- in vscode a window contains multiple tabs
-- the following rearrange the window layout (and together with all the tabs that belong to the window)
keymap("n", "<C-w><C-l>", code_do("workbench.action.navigateRight"), opts_desc("Focus window right"))
keymap("n", "<C-w><C-h>", code_do("workbench.action.navigateLeft"), opts_desc("Focus window left"))
keymap("n", "<C-w><C-k>", code_do("workbench.action.navigateUp"), opts_desc("Focus window up"))
keymap("n", "<C-w><C-j>", code_do("workbench.action.navigateDown"), opts_desc("Focus window down"))
keymap("n", "<C-w>H", code_do("workbench.action.moveActiveEditorGroupLeft"), opts_desc("Move window left"))
keymap("n", "<C-w>J", code_do("workbench.action.moveActiveEditorGroupDown"), opts_desc("Move window down"))
keymap("n", "<C-w>K", code_do("workbench.action.moveActiveEditorGroupUp"), opts_desc("Move window up"))
keymap("n", "<C-w>L", code_do("workbench.action.moveActiveEditorGroupRight"), opts_desc("Move window right"))

-- zen mode
keymap("n", "<Leader>z", code_do("workbench.action.toggleZenMode"), opts)

-- the following config move tab to different window
keymap("n", "<Leader>wu", code_do("workbench.action.moveEditorToAboveGroup"), opts)
keymap("n", "<Leader>wd", code_do("workbench.action.moveEditorToBelowGroup"), opts)
keymap("n", "<Leader>wb", code_do("workbench.action.moveEditorToLeftGroup"), opts) --backward
keymap("n", "<Leader>wf", code_do("workbench.action.moveEditorToRightGroup"), opts) --forward

-- tab related keymaps
keymap("n", "<Leader>o", [[:Tabonly<cr>]], opts_desc("tab: delete other tabs"))
keymap("n", "[t", [[gT]], opts_desc("tab: previous tab"))
keymap("n", "]t", [[gt]], opts_desc("tab: next tab"))
keymap("n", "<Leader>1", code_do("workbench.action.openEditorAtIndex1"), opts_desc("tab: 1st tab"))
keymap("n", "<Leader>2", code_do("workbench.action.openEditorAtIndex2"), opts_desc("tab: 2nd tab"))
keymap("n", "<Leader>3", code_do("workbench.action.openEditorAtIndex3"), opts_desc("tab: 3rd tab"))
keymap("n", "<Leader>4", code_do("workbench.action.openEditorAtIndex4"), opts_desc("tab: 4st tab"))
keymap("n", "<Leader>5", code_do("workbench.action.openEditorAtIndex5"), opts_desc("tab: 5st tab"))
keymap("n", "<Leader>6", code_do("workbench.action.openEditorAtIndex6"), opts_desc("tab: 6st tab"))
keymap("n", "<Leader>7", code_do("workbench.action.openEditorAtIndex7"), opts_desc("tab: 7st tab"))
keymap("n", "<Leader>8", code_do("workbench.action.openEditorAtIndex8"), opts_desc("tab: 8st tab"))
keymap("n", "<Leader>9", code_do("workbench.action.openEditorAtIndex9"), opts_desc("tab: 9st tab"))

-- explorer
vim.keymap.set("n", "<leader>e", function()
	require("vscode").action("workbench.view.explorer")
end, { noremap = true, silent = true, desc = "Toggle VSCode Explorer" })

-- VISUAL MODE keymaps
-- lsp keymaps
keymap("v", "grf", code_do("editor.action.formatSelection"), opts)
keymap("v", "<Leader>la", code_do("editor.action.quickFix"), opts)
keymap("v", "<Leader>lr", code_do("editor.action.refactor"), opts)
keymap("v", "<Leader>fc", code_do("workbench.action.showCommands"), opts)

return {}
-- return M