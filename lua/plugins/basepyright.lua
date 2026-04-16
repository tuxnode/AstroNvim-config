-- lua/plugins/basepyright.lua
return {
  "neovim/nvim-lspconfig", -- 仍可保留用于其他功能，或直接删掉
  config = function()
    vim.lsp.config("basedpyright", {
      settings = {
        basedpyright = {
          typeCheckingMode = "standard",
          analysis = {
            reportUnusedVariable = "none",
          },
        },
      },
    })

    vim.lsp.enable("basedpyright")
  end,
}
