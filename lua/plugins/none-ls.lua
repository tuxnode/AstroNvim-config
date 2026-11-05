-- Customize None-ls sources

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    {
      "jay-babu/mason-null-ls.nvim",
      opts = {
        handlers = {
          clang_format = function()
            local null_ls = require "null-ls"

            null_ls.register(null_ls.builtins.formatting.clang_format.with {
              filetypes = { "cpp" },
            })
          end,
        },
      },
    },
  },
}
