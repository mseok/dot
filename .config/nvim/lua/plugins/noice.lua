require("noice").setup({
  presets = {
    bottom_search = false,
    command_palette = true,
    long_message_to_split = true,
    inc_rename = true,
  },
	routes = {
		{
			view = "notify",
			filter = { event = "msg_showmode" },
		},
    {
      filter = {
        event = "msg_showmode",
        -- kind = "",
        -- find = "INSERT",
      },
      opts = { skip = true },
    },
	},
  cmdline = {
    format = {
      cmdline = { icon = ">" },
      search_down = { icon = "/" },
      search_up = { icon = "\\" },
      filter = { icon = "$" },
      lua = { icon = "☾" },
      help = { icon = "?" },
    },
	},
  -- views = {
  --   cmdline_popup = {
  --     border = {
  --       style = "none",
  --       padding = { 2, 3 },
  --     },
  --     filter_options = {},
  --     win_options = {
  --       winhighlight = "NormalFloat:NormalFloat,FloatBorder:NormalFloat",
  --     },
  --   },
  -- },
  views = {
    cmdline_popup = {
      position = {
        row = 5,
        col = "50%",
      },
      size = {
        width = 60,
        height = "auto",
      },
    },
    popupmenu = {
      relative = "editor",
      position = {
        row = 8,
        col = "50%",
      },
      size = {
        width = 60,
        height = 10,
      },
      border = {
        style = "rounded",
        padding = { 0, 1 },
      },
      win_options = {
        winhighlight = {
          Normal = "Normal",
          FloatBorder = "DiagnosticInfo"
        },
      },
    },
  },
})
