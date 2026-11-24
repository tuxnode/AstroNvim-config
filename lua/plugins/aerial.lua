-- Symbol outline: compact, structure-only view for C/C++ sources
---@type LazySpec
return {
  "stevearc/aerial.nvim",
  opts = {
    filter_kind = { "Namespace", "Class", "Struct", "Constructor", "Method", "Function" },
    show_guides = true,
    layout = {
      min_width = 20,
      preserve_equality = false,
      -- keep our fixed sidebar width instead of shrinking to the symbol names
      resize_to_content = false,
    },
    -- compact tree: one column per nesting level instead of two
    guides = {
      mid_item = "├",
      last_item = "└",
      nested_top = "│",
      whitespace = " ",
    },
    -- hide per-kind icons so each line is just indentation + name
    icons = {
      Namespace = "",
      Class = "",
      Struct = "",
      Constructor = "",
      Method = "",
      Function = "",
    },
  },
}
