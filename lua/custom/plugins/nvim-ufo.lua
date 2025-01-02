-- this is a plugin for better folding in nvim
return {
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    config = function()
      -- Key mappings for ufo
      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

      -- Option 3: treesitter as a main provider instead of LSP or coc.nvim
      require('ufo').setup {
        provider_selector = function(bufnr, filetype, buftype)
          return { 'lsp', 'indent' }
          -- return { 'treesitter', 'indent' }
        end,
      }
    end,
  },
}
