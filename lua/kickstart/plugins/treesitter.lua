return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    -- The `master` branch is frozen and does NOT support Neovim 0.12 (see its README).
    -- `main` is the rewrite that supports 0.12+. It uses a different API: no `opts`/modules table,
    -- parsers are installed via `install()`, and highlighting is started per-buffer.
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      -- `main`-branch replacement for `ensure_installed`. Add languages you edit here.
      local ensure_installed = {
        'bash',
        'c',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
        'yaml',
        'json',
        'python',
        'javascript',
        'typescript',
        'tsx',
        'terraform',
      }
      -- Install only the parsers that aren't already present (avoids recompiling on every startup).
      local installed = require('nvim-treesitter.config').get_installed 'parsers'
      local missing = vim.tbl_filter(function(lang)
        return not vim.tbl_contains(installed, lang)
      end, ensure_installed)
      if #missing > 0 then
        require('nvim-treesitter').install(missing)
      end

      -- On `main` there is no `highlight = { enable = true }` module; start treesitter per-buffer.
      -- (Folding is left to nvim-ufo; we don't touch foldexpr here.)
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
          if not lang or lang == '' then
            return
          end
          -- Only start if a parser for this language is available; pcall keeps unknown
          -- filetypes from raising errors.
          if pcall(vim.treesitter.language.add, lang) then
            pcall(vim.treesitter.start, ev.buf, lang)
          end
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
