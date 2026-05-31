return {
  {
    "voldikss/vim-translator",
    lazy = false, -- 建议不延迟加载，或根据需要设置为 keys 加载
    init = function()
      -- 设置默认翻译引擎（例如使用 bing 或 google）
      vim.g.translator_default_engines = { "bing", "youdao" }
    end,
  },
}
