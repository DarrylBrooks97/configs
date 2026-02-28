-- Image viewing in Neovim using Kitty graphics protocol
-- Requires: Kitty terminal (or compatible), ImageMagick, and luarocks magick
--
-- Install system dependencies:
--   brew install imagemagick luajit luarocks
--   luarocks --lua-version=5.1 install magick

return {
  '3rd/image.nvim',
  build = false, -- disable build, rocks handled by lazy.nvim
  lazy = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'vhyrro/luarocks.nvim',
      priority = 1001,
      opts = {
        rocks = { 'magick' },
      },
    },
  },
  opts = {
    backend = 'kitty', -- or 'ueberzug' if not using Kitty
    processor = 'magick_rock', -- requires luarocks magick
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
        only_render_image_at_cursor = false,
        floating_windows = false,
        filetypes = { 'markdown', 'vimwiki' },
      },
      neorg = {
        enabled = true,
        filetypes = { 'norg' },
      },
      typst = {
        enabled = true,
        filetypes = { 'typst' },
      },
      html = {
        enabled = false,
      },
      css = {
        enabled = false,
      },
    },
    max_width = nil, -- nil = auto
    max_height = nil,
    max_width_window_percentage = nil,
    max_height_window_percentage = 50,
    window_overlap_clear_enabled = false,
    window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
    editor_only_render_when_focused = false,
    tmux_show_only_in_active_window = false,
    hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp', '*.avif' },
  },
}
