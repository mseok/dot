return {
  "chipsenkbeil/distant.nvim",
  branch = "v0.3",
  config = function()
    require("distant"):setup(
        {
            ["mseok@messi.kaist.ac.kr"] = {
                lsp = {
                    ["/home/mseok/work/DL/IF/RDBDock"] = {
                        -- vim local share lsp path
                        cmd = vim.fn.stdpath("data") .. "/mason/bin/pyright",
                    }
                }
            }
        }
    )
  end,
}
