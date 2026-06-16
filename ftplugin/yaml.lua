vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Treesitter-based folding
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt_local.foldlevel = 99

-- Shift-Tab dedent in insert mode
vim.keymap.set('i', '<S-Tab>', '<C-d>', { buffer = true, desc = 'Dedent line' })

-- ( / ) — jump to start/end of current indent block
local function jump_block_boundary(direction)
  local cur_line = vim.fn.line '.'
  local cur_indent = vim.fn.indent(cur_line)
  local total_lines = vim.fn.line '$'
  local target = cur_line

  local step = direction == 'up' and -1 or 1
  local line = cur_line + step

  while line >= 1 and line <= total_lines do
    local text = vim.fn.getline(line)
    if text:match '^%s*$' then
      break
    end
    local indent = vim.fn.indent(line)
    if indent < cur_indent then
      break
    end
    if indent == cur_indent then
      target = line
    end
    line = line + step
  end

  if target ~= cur_line then
    vim.cmd(tostring(target))
  end
end

vim.keymap.set('n', '(', function()
  jump_block_boundary 'up'
end, { buffer = true, desc = 'Jump to start of indent block' })

vim.keymap.set('n', ')', function()
  jump_block_boundary 'down'
end, { buffer = true, desc = 'Jump to end of indent block' })

-- { / } — jump to previous/next sibling at same indent level (skipping nested content)
local function jump_sibling(direction)
  local cur_line = vim.fn.line '.'
  local cur_indent = vim.fn.indent(cur_line)
  local total_lines = vim.fn.line '$'

  local step = direction == 'up' and -1 or 1
  local line = cur_line + step

  while line >= 1 and line <= total_lines do
    local text = vim.fn.getline(line)
    -- Skip blank lines
    if not text:match '^%s*$' then
      local indent = vim.fn.indent(line)
      -- Found a sibling at same level
      if indent == cur_indent then
        vim.cmd(tostring(line))
        return
      end
      -- Hit a parent — no more siblings in this direction
      if indent < cur_indent then
        return
      end
      -- indent > cur_indent: nested content, skip over it
    end
    line = line + step
  end
end

vim.keymap.set('n', '{', function()
  jump_sibling 'up'
end, { buffer = true, desc = 'Jump to previous sibling (same indent)' })

vim.keymap.set('n', '}', function()
  jump_sibling 'down'
end, { buffer = true, desc = 'Jump to next sibling (same indent)' })
