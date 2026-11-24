-- Integrated left sidebar: file tree (neo-tree) on top, symbol outline (aerial) below.
-- Both windows share one column so they are visible at the same time.
local M = {}

---@param ft? string
---@return boolean
function M.is_sidebar(ft)
  ft = ft or vim.bo.filetype
  return ft == "neo-tree" or ft == "aerial"
end

---@param ft string
---@return integer?
local function win_by_ft(ft)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == ft then return win end
  end
end

--- Find the window that holds actual code (skips sidebar and floating windows)
---@return integer?
local function code_win()
  local cur = vim.api.nvim_get_current_win()
  if
    vim.api.nvim_win_get_config(cur).relative == ""
    and not M.is_sidebar(vim.bo[vim.api.nvim_win_get_buf(cur)].filetype)
  then
    return cur
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
      if not M.is_sidebar(vim.bo[vim.api.nvim_win_get_buf(win)].filetype) then return win end
    end
  end
end

--- Create the aerial window below the neo-tree window if it does not exist yet
---@param src_win integer
---@return integer?
local function open_aerial_below(src_win)
  local neo = win_by_ft "neo-tree"
  if not neo then return end
  local existing = win_by_ft "aerial"
  if existing then return existing end

  local new_win
  vim.api.nvim_win_call(neo, function()
    vim.cmd "belowright split"
    new_win = vim.api.nvim_get_current_win()
  end)
  if not new_win or not vim.api.nvim_win_is_valid(new_win) then return end

  local ok = pcall(require("aerial.window").open_aerial_in_win, vim.api.nvim_win_get_buf(src_win), src_win, new_win)
  if not ok then
    pcall(vim.api.nvim_win_close, new_win, true)
    return
  end
  return new_win
end

---@param neo integer
---@param aer integer
local function resize(neo, aer)
  pcall(vim.api.nvim_win_set_width, neo, 32)
  local total = vim.o.lines - vim.o.cmdheight - 1
  local height = math.max(8, math.min(math.floor(total * 0.4), total - 10))
  pcall(vim.api.nvim_win_set_height, aer, height)
end

--- Make sure the outline is stacked below the file tree
function M.arrange()
  if vim.g.sidebar_disabled then return end
  local neo = win_by_ft "neo-tree"
  if not neo then return end
  local src = code_win()
  if not src then return end
  if win_by_ft "aerial" then return end

  local aer = open_aerial_below(src)
  if aer then resize(neo, aer) end
end

--- Open the sidebar (file tree + outline) unless the user hid it
function M.open()
  if vim.g.sidebar_disabled then return end
  if not code_win() then return end
  if not win_by_ft "neo-tree" then
    pcall(require("neo-tree.command").execute, { action = "show", source = "filesystem", reveal = false })
  end
  vim.schedule(M.arrange)
end

--- Toggle the whole sidebar. Hiding it also disables auto-open until toggled back on.
function M.toggle()
  local neo = win_by_ft "neo-tree"
  local aer = win_by_ft "aerial"
  if neo or aer then
    vim.g.sidebar_disabled = true
    if aer then pcall(vim.api.nvim_win_close, aer, true) end
    pcall(require("neo-tree.command").execute, { action = "close" })
    local src = code_win()
    if src then vim.api.nvim_set_current_win(src) end
  else
    vim.g.sidebar_disabled = false
    M.open()
  end
end

--- Toggle only the symbol outline, keeping it stacked below the file tree
function M.toggle_symbols()
  local aer = win_by_ft "aerial"
  if aer then
    pcall(vim.api.nvim_win_close, aer, true)
    return
  end
  local src = code_win()
  if not src then return end
  local neo = win_by_ft "neo-tree"
  if neo then
    local new_win = open_aerial_below(src)
    if new_win then resize(neo, new_win) end
  else
    pcall(require("aerial").open, false, "left")
  end
end

--- Auto-open the sidebar when a normal file buffer is entered
---@param bufnr? integer
function M.auto_open(bufnr)
  if vim.g.sidebar_disabled then return end
  bufnr = bufnr and bufnr > 0 and bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.bo[bufnr].buftype ~= "" then return end
  if vim.api.nvim_win_get_config(0).relative ~= "" then return end -- skip floating windows
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return end
  local stat = vim.uv.fs_stat(name)
  if not stat or stat.type ~= "file" then return end

  vim.schedule(function()
    if vim.api.nvim_get_current_buf() == bufnr then M.open() end
  end)
end

return M
