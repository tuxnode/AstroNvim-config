-- Top winbar: file path breadcrumbs + current symbol hierarchy (via aerial/LSP)
---@type LazySpec
return {
  "rebelot/heirline.nvim",
  opts = function(_, opts)
    local status = require "astroui.status"
    local path_func = status.provider.filename { modify = ":.:h", fallback = "" }

    ---@param self table
    local function is_sidebar(self)
      local ok, winid = pcall(vim.fn.win_getid, self.winnr)
      if not ok or winid == 0 then return false end
      local ft = vim.bo[vim.api.nvim_win_get_buf(winid)].filetype
      return ft == "neo-tree" or ft == "aerial"
    end

    opts.winbar = {
      init = function(self) self.bufnr = vim.api.nvim_get_current_buf() end,
      fallthrough = false,
      -- hide the winbar inside the sidebar windows
      {
        condition = is_sidebar,
        provider = "",
      },
      -- inactive windows: show the directory path and file name only
      {
        condition = function() return not status.condition.is_active() end,
        status.component.separated_path { path_func = path_func, padding = { left = 2 } },
        status.component.file_info {
          file_icon = { hl = status.hl.file_icon "winbar", padding = { left = 0 } },
          filename = {},
          filetype = false,
          file_modified = false,
          file_read_only = false,
          hl = status.hl.get_attributes("winbarnc", true),
          surround = false,
          update = "BufEnter",
        },
      },
      -- active window: path + file name + symbol breadcrumbs
      {
        status.component.separated_path { path_func = path_func },
        status.component.file_info {
          file_icon = { hl = status.hl.filetype_color, padding = { left = 0 } },
          filename = {},
          filetype = false,
          file_modified = false,
          file_read_only = false,
          hl = status.hl.get_attributes("winbar", true),
          surround = false,
          update = "BufEnter",
        },
        status.component.breadcrumbs {
          icon = { hl = true },
          hl = status.hl.get_attributes("winbar", true),
          prefix = true,
          padding = { left = 0 },
        },
      },
    }
  end,
}
