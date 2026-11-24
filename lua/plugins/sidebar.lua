-- Integrated sidebar (file tree + outline) mappings and auto-open behavior
---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = function(_, opts)
    local maps = opts.mappings

    maps.n["<Leader>e"] = { function() require("user.sidebar").toggle() end, desc = "Toggle Sidebar" }
    maps.n["<Leader>lS"] = { function() require("user.sidebar").toggle_symbols() end, desc = "Symbols outline" }

    opts.autocmds.sidebar_auto_open = {
      {
        event = "BufEnter",
        desc = "Auto open file tree and outline sidebar",
        callback = function(args) require("user.sidebar").auto_open(args.buf) end,
      },
    }
  end,
}
