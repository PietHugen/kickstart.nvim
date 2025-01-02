return {
  {
    'ellisonleao/glow.nvim',
    cmd = 'Glow',
    config = function()
      require('glow').setup {
        style = '~/github/glamour/styles/tokyo_night.json', -- filled automatically with your current editor background, you can override using glow json style
        pager = false,
        -- width_ratio = 1.5, -- maximum width of the Glow window compared to the nvim window size (overrides `width`)
        -- height_ratio = 0.9,
      }
    end,
    vim.keymap.set('n', '<leader>mp', ':Glow<cr>', { desc = 'Call Glow, preview markdown' }),
  },
}
