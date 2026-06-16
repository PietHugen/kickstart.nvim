-- Markdown preview with `glow` in a floating window.
--
-- Why not glow.nvim? glow.nvim pipes glow's stdout into a buffer, so glamour
-- detects "not a terminal" and strips ALL color (leaving only bold/italic).
-- Running glow inside a PTY (jobstart{ term = true }) makes it emit the full
-- truecolor theme, which Neovim's terminal then renders.

local style = vim.fn.expand '~/github/glamour/styles/tokyo_night.json'

local function glow_preview()
  if vim.bo.filetype ~= 'markdown' then
    vim.notify('Glow: current buffer is not markdown', vim.log.levels.WARN)
    return
  end
  if vim.fn.executable 'glow' == 0 then
    vim.notify('Glow: `glow` executable not found on PATH', vim.log.levels.ERROR)
    return
  end

  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then
    vim.notify('Glow: buffer has no file on disk', vim.log.levels.WARN)
    return
  end

  -- Centered floating window.
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.85)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' Markdown Preview ',
    title_pos = 'center',
  })

  -- Run glow in a PTY (term = true) so it produces truecolor output.
  local cmd = { 'glow' }
  if vim.fn.filereadable(style) == 1 then
    vim.list_extend(cmd, { '-s', style })
  end
  vim.list_extend(cmd, { '-w', tostring(width - 2), file })
  vim.fn.jobstart(cmd, { term = true })

  -- Quick close from the preview window.
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set('n', 'q', close, { buffer = buf, nowait = true, desc = 'Close preview' })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true, desc = 'Close preview' })
  vim.cmd 'stopinsert'
end

vim.keymap.set('n', '<leader>mp', glow_preview, { desc = 'Markdown [P]review (glow)' })

-- No plugin needed; glow.nvim is replaced by the function above.
return {}
