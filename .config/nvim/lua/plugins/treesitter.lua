require "nvim-treesitter.install".compilers = { "gcc" }  -- if cc version is too low

require "nvim-treesitter.configs".setup {
  ensure_installed = "python", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  highlight = {
    enable = true,              -- false will disable the whole extension
    additional_vim_regex_highlighting = true,
  },
  incremental_selection = {
    enable = true,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
    },
  },
}
