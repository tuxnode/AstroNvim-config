if vim.g.neovide then
  vim.o.guifont = "JetBrainsMono Nerd Font:h23"
  -- vim.o.guifont = "*:h22"

  -- Neovide 特有的丝滑配置（可选优化）
  vim.g.neovide_cursor_animation_length = 0.13    -- 光标移动动画时长
  vim.g.neovide_cursor_vfx_mode = "wireframe"       -- 光标特效：电磁炮（还有 "ripple", "wireframe" 等）
  vim.g.neovide_refresh_rate = 60                -- 刷新率（根据你的显示器调整）
  vim.g.neovide_transparency = 0.9                -- 窗口透明度
end

return {}
