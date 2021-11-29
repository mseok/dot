vim.o.completeopt = "menu,menuone,noselect"
local cmp = require "cmp"
cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
	mapping = {
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
    ["<C-e>"] = cmp.mapping.close(),
  },
  formatting = {
    format = function(entry, vim_item)
      vim_item.menu = ({
        nvim_lsp = "[LSP]",
        buffer = "[Buffer]",
        path = "[Path]",
        luasnip = "[Snippet]"
      })[entry.source.name]
      return vim_item
    end,
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "path" },
    {
      name = "buffer",
      option = {
        -- All buffers (include hidden buffers)
        get_bufnrs = function()
          return vim.api.nvim_list_bufs()
        end
        -- Only Visible Buffers
        -- get_bufnrs = function()
        --   local bufs = {}
        --   for _, win in ipairs(vim.api.nvim_list_wins()) do
        --     bufs[vim.api.nvim_win_get_buf(win)] = true
        --   end
        --   return vim.tbl_keys(bufs)
        -- end
      }
    },
    { name = "luasnip" },
  },
})

cmp.setup.cmdline('/', {
  sources = {
    { name = 'buffer' }
  }
})

-- cmp.setup.cmdline(':', {
--   sources = cmp.config.sources({
--     { name = 'path' }
--   }, {
--     { name = 'cmdline' }
--   })
-- })
