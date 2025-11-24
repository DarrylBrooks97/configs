return {
  {
    'saghen/blink.cmp',
    opts = function(_, opts)
      opts.completion = vim.tbl_deep_extend('force', opts.completion or {}, {
        trigger = {
          -- Immediately show completion items when typing keywords
          show_on_keyword = true,
        },
        list = {
          selection = {
            -- Always select the top match and preview it inline
            preselect = true,
            auto_insert = true,
          },
        },
        ghost_text = {
          enabled = true,
          show_with_menu = true,
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 250,
        },
      })
    end,
  },
}
