-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

-- Organize Rust imports on save with rust-analyzer's `Merge imports` code action,
-- then let AstroLSP format the buffer with rustfmt. This is registered as a global
-- autocommand, which runs before the buffer-local autoformat autocommand that
-- AstroLSP creates when rust_analyzer attaches.
--
-- NOTE: as of rust-analyzer 1.99.1 `source.organizeImports` is no longer exposed,
-- and `Merge imports` does not remove unused imports.
---@param bufnr integer buffer to organize imports for
local function rust_merge_imports(bufnr)
  if vim.bo[bufnr].filetype ~= "rust" then return end

  -- respect the AstroLSP autoformat toggles (`<Leader>uf` buffer / `<Leader>uF` global)
  local astrolsp = require "astrolsp"
  local autoformat = vim.b[bufnr].autoformat
  if autoformat == nil then autoformat = astrolsp.autoformat_enabled(bufnr) end
  if not autoformat then return end

  local client
  for _, c in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    -- rustaceanvim names the client `rust-analyzer`, while AstroLSP/nvim-lspconfig uses `rust_analyzer`
    if c.name == "rust-analyzer" or c.name == "rust_analyzer" then
      client = c
      break
    end
  end
  if not client or not client:supports_method("textDocument/codeAction", bufnr) then return end

  local timeout = astrolsp.format_opts.timeout_ms or 3000
  local last_line = vim.api.nvim_buf_line_count(bufnr) - 1
  local last_col = #(vim.api.nvim_buf_get_lines(bufnr, last_line, last_line + 1, false)[1] or "")
  local response = client:request_sync("textDocument/codeAction", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = { start = { line = 0, character = 0 }, ["end"] = { line = last_line, character = last_col } },
    context = { diagnostics = {}, only = { "refactor.rewrite" } },
  }, timeout, bufnr)
  if not response or response.err or type(response.result) ~= "table" then return end

  for _, action in ipairs(response.result) do
    if action.title == "Merge imports" then
      -- actions are lazily resolved when the server advertises `codeAction/resolve`
      if not action.edit and action.data then
        local resolved = client:request_sync("codeAction/resolve", action, timeout, bufnr)
        if resolved and not resolved.err and resolved.result then action = resolved.result end
      end
      if action.edit then
        local edit = action.edit
        -- `Merge imports` only edits the current file. Drop rust-analyzer's
        -- "edit outside of the workspace" confirmation so that saving never blocks on it.
        if edit.changeAnnotations then
          edit.changeAnnotations = nil
          for _, change in ipairs(edit.documentChanges or {}) do
            for _, text_edit in ipairs(change.edits or {}) do
              if text_edit.annotationId then text_edit.annotationId = nil end
            end
          end
        end
        vim.lsp.util.apply_workspace_edit(edit, client.offset_encoding or "utf-16")
      elseif action.command then
        client:exec_cmd(action, { bufnr = bufnr })
      end
      break
    end
  end
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- Autocommands registered globally through AstroCore
    autocmds = {
      autoread_checktime = {
        {
          event = { "BufEnter", "CursorHold", "CursorHoldI", "FocusGained", "VimResume" },
          desc = "Reload files changed outside of Neovim",
          callback = function(args)
            if vim.bo[args.buf].buftype == "" and vim.bo[args.buf].modifiable then vim.cmd "checktime" end
          end,
        },
      },
      rust_merge_imports = {
        {
          event = "BufWritePre",
          pattern = "*.rs",
          desc = "Merge Rust imports on save",
          callback = function(args) rust_merge_imports(args.buf) end,
        },
      },
    },
    -- passed to `vim.filetype.add`
    filetypes = {
      -- see `:h vim.filetype.add` for usage
      extension = {
        foo = "fooscript",
      },
      filename = {
        [".foorc"] = "fooscript",
      },
      pattern = {
        [".*/etc/foo/.*"] = "fooscript",
      },
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        autoread = true, -- reload files changed outside of Neovim
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "yes", -- sets vim.opt.signcolumn to yes
        wrap = false, -- sets vim.opt.wrap
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- Translate
        ["<Leader>tt"] = { desc = "󰗊 Translation" }, -- 定义一个翻译前缀菜单
        ["<Leader>ttw"] = { "<cmd>TranslateW<cr>", desc = "翻译单词 (窗口)" },
        ["<Leader>ttr"] = { "<cmd>TranslateR<cr>", desc = "替换为翻译结果" },

        -- second key is the lefthand side of the map

        -- navigate buffer tabs
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },

        -- tables with just a `desc` key will be registered with which-key if it's installed
        -- this is useful for naming menus
        -- ["<Leader>b"] = { desc = "Buffers" },

        -- setting a mapping to false will disable it
        -- ["<C-S>"] = false,
      },
      v = {
        ["<Leader>tt"] = { "<cmd>TranslateV<cr>", desc = "翻译选中内容" },
      },
    },
  },
}
