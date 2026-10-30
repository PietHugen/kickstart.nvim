-- this is a plugin for better folding in nvim
return {
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    -- Only needed once a buffer is open; not at startup.
    event = { 'BufReadPost', 'BufNewFile' },
    keys = {
      {
        'zR',
        function()
          require('ufo').openAllFolds()
        end,
        desc = 'Open all folds',
      },
      {
        'zM',
        function()
          require('ufo').closeAllFolds()
        end,
        desc = 'Close all folds',
      },
    },
    config = function()
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
