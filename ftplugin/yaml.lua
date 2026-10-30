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

-- ( / ) — jump to start/end of the current indent block.
-- Walks from the cursor, skipping blank lines, and stops at the first non-blank line
-- with a smaller indent. Returns the target line, or nil when the cursor should not
-- move. With same-indent siblings it lands on the far-most sibling; with none (a
-- container or a leaf) it closes to the edge of the nested block.
local function jump_block_boundary(direction)
  local cur_line = vim.fn.line '.'
  local cur_indent = vim.fn.indent(cur_line)
  local total_lines = vim.fn.line '$'

  local step = direction == 'up' and -1 or 1
  local line = cur_line + step

  local last_same = nil
  local last_any = nil

  while line >= 1 and line <= total_lines do
    local text = vim.fn.getline(line)
    if not text:match '^%s*$' then
      local indent = vim.fn.indent(line)
      if indent < cur_indent then
        break
      end
      if indent == cur_indent then
        last_same = line
      end
      last_any = line
    end
    line = line + step
  end

  local target = last_same or last_any
  if target and target ~= cur_line then
    return target
  end
  return nil
end

-- { / } — jump to the previous/next sibling at the same indent level (skipping nested
-- content). Returns the target line, or nil when there is no such sibling.
local function jump_sibling(direction)
  local cur_line = vim.fn.line '.'
  local cur_indent = vim.fn.indent(cur_line)
  local total_lines = vim.fn.line '$'

  local step = direction == 'up' and -1 or 1
  local line = cur_line + step

  while line >= 1 and line <= total_lines do
    local text = vim.fn.getline(line)
    if not text:match '^%s*$' then
      local indent = vim.fn.indent(line)
      if indent == cur_indent then
        return line
      end
      if indent < cur_indent then
        return nil
      end
    end
    line = line + step
  end
  return nil
end

-- Normal mode: move the cursor to the helper's target line.
local function jump_normal(helper, direction)
  local t = helper(direction)
  if t then
    vim.api.nvim_win_set_cursor(0, { t, 0 })
  end
end

-- 0-based byte column of a line's last character (so a char-wise visual cursor lands on
-- the final character). Strips a trailing run of UTF-8 continuation bytes (0x80-0xBF) so
-- the index lands on the last character's lead byte instead of mid-character.
local function last_col0(line_no)
  local s = vim.fn.getline(line_no)
  local trail = s:match '[\128-\191]+$'
  return #s - 1 - (trail and #trail or 0)
end

-- Visual mode: move the *moving* end of the selection (the anchor stays put, and visual
-- mode is preserved). Uses nvim_win_set_cursor (a direct API call, not an ex-command)
-- because setpos("'>") / :line only move a derived mark and do not change the real
-- selection. Line-wise (V) targets col 0; char-wise (v) targets the last character.
local function jump_visual(helper, direction)
  local t = helper(direction)
  if not t then
    return
  end
  local col = (vim.fn.mode() == 'V') and 0 or last_col0(t)
  vim.api.nvim_win_set_cursor(0, { t, col })
end

vim.keymap.set('n', '(', function()
  jump_normal(jump_block_boundary, 'up')
end, { buffer = true, desc = 'Jump to start of indent block' })

vim.keymap.set('v', '(', function()
  jump_visual(jump_block_boundary, 'up')
end, { buffer = true, desc = 'Extend selection to start of indent block' })

vim.keymap.set('n', ')', function()
  jump_normal(jump_block_boundary, 'down')
end, { buffer = true, desc = 'Jump to end of indent block' })

vim.keymap.set('v', ')', function()
  jump_visual(jump_block_boundary, 'down')
end, { buffer = true, desc = 'Extend selection to end of indent block' })

vim.keymap.set('n', '{', function()
  jump_normal(jump_sibling, 'up')
end, { buffer = true, desc = 'Jump to previous sibling (same indent)' })

vim.keymap.set('v', '{', function()
  jump_visual(jump_sibling, 'up')
end, { buffer = true, desc = 'Extend selection to previous sibling (same indent)' })

vim.keymap.set('n', '}', function()
  jump_normal(jump_sibling, 'down')
end, { buffer = true, desc = 'Jump to next sibling (same indent)' })

vim.keymap.set('v', '}', function()
  jump_visual(jump_sibling, 'down')
end, { buffer = true, desc = 'Extend selection to next sibling (same indent)' })
