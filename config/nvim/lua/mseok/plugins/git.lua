return {
	-- git and projects
	{
		"NeogitOrg/neogit",
		lazy = true,
		cmd = "Neogit",
		config = function()
			require("neogit").setup({
				disable_commit_confirmation = true,
				integrations = {
					diffview = true,
				},
			})
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
        lazy = true,
        cmd = "Gitsigns",
		config = function()
			require("gitsigns").setup({})
		end,
	},
}
