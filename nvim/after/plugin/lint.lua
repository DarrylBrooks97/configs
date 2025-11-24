local ok, lint = pcall(require, "lint")
if not ok then return end

-- Only run linters when they exist and for real file buffers
local function should_lint()
  if vim.bo.buftype ~= '' then return false end -- skip prompts/terms/etc
  local ft = vim.bo.filetype
  local linters = lint.linters_by_ft and lint.linters_by_ft[ft]
  if not linters or vim.tbl_isempty(linters) then return false end

  -- Basic executable check to avoid ENOENT (e.g. missing eslint_d)
  for _, name in ipairs(linters) do
    local l = lint.linters[name]
    local cmd = l and l.cmd or name
    if type(cmd) == 'function' then cmd = cmd() end
    if type(cmd) == 'table' then cmd = cmd[1] end
    if cmd and vim.fn.executable(cmd) == 1 then
      return true
    end
  end
  return false
end

local group = vim.api.nvim_create_augroup('NvimLintAutogroup', { clear = true })
vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
  group = group,
  callback = function()
    if should_lint() then
      lint.try_lint()
    end
  end,
})

-- For JS/TS, only run eslint_d if present; otherwise skip silently
if lint.linters and lint.linters.eslint_d then
  local orig = lint.linters.eslint_d
  lint.linters.eslint_d = vim.tbl_extend('force', orig, {
    condition = function(ctx)
      return vim.fn.executable('eslint_d') == 1 or vim.fn.executable('eslint') == 1
    end,
  })
end
