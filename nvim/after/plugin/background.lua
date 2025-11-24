-- Ensure truecolor; do not force dark backgrounds or override light themes
vim.opt.termguicolors = true

local function apply_bg()
  -- Only apply custom background tweaks for dark mode; skip for light themes (e.g., Rose Pine Dawn)
  if vim.o.background == 'light' then return end
  local bg = "#101010"
  for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat", "SignColumn", "LineNr", "EndOfBuffer" }) do
    vim.api.nvim_set_hl(0, group, { bg = bg })
  end
end

apply_bg()

vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_bg })
