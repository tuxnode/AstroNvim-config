-- GitHub's official Neovim themes
-- https://github.com/projekt0n/github-nvim-theme
return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false, -- load at startup since it is the active colorscheme
    priority = 1000, -- load before other start plugins
    config = function()
      require("github-theme").setup {
        options = {
          transparent = false,
          styles = {
            comments = "italic",
            keywords = "bold",
          },
        },
      }

      -- other variants: github_dark_default, github_dark_dimmed,
      -- github_dark_high_contrast, github_light, github_light_default, ...
      vim.cmd.colorscheme "github_dark"
    end,
  },
}
