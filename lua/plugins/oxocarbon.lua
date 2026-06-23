return {
  {
    "nyoom-engineering/oxocarbon.nvim",
    priority = 1000,
    config = function()
      vim.cmd "colorscheme oxocarbon"
      local hl = vim.api.nvim_set_hl
      local groups = {
        "Normal", "NormalNC", "NormalFloat", "SignColumn", "EndOfBuffer",
        "VertSplit", "WinSeparator", "LineNr", "CursorLineNr", "FoldColumn",
        "Folded", "NonText", "SpecialKey",
      }
      for _, g in ipairs(groups) do
        hl(0, g, { bg = "NONE" })
      end
    end,
  },
}
