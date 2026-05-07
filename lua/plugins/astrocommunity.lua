-- 文件路径: lua/plugins/astrocommunity.lua
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.python" }, -- 配合你的 basepyright.lua
  { import = "astrocommunity.pack.toml" },
  { import = "astrocommunity.colorscheme.oxocarbon-nvim" }, -- 配合你的 oxocarbon.lua
}
