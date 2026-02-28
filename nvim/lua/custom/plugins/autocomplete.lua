-- Autocomplete configuration for blink.cmp + Supermaven AI completions
-- Fixes: Enter key selection, no line skip, better preselection
return {
  -- Supermaven AI code completion
  {
    'supermaven-inc/supermaven-nvim',
    event = 'InsertEnter',
    opts = {
      keymaps = {
        accept_suggestion = '<Tab>',
        clear_suggestion = '<C-]>',
        accept_word = '<C-j>',
      },
      -- Ignore certain filetypes
      ignore_filetypes = { 'TelescopePrompt', 'neo-tree', 'neo-tree-popup' },
      -- Show suggestions in gray ghost text
      color = {
        suggestion_color = '#808080',
        cterm = 244,
      },
      -- Log level for debugging
      log_level = 'off',
      -- Disable inline completion if you only want blink.cmp integration
      disable_inline_completion = false,
      -- Disable keymaps if you want to configure them differently
      disable_keymaps = false,
    },
  },
  {
    'saghen/blink.cmp',
    opts = function(_, opts)
      opts.keymap = vim.tbl_deep_extend('force', opts.keymap or {}, {
        -- Use 'enter' preset for Enter key to accept completions
        preset = 'enter',
        -- Additional keymaps
        ['<C-y>'] = { 'select_and_accept' },
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<C-p>'] = { 'select_prev', 'fallback' },
        ['<C-n>'] = { 'select_next', 'fallback' },
        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
        ['<Tab>'] = { 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
        -- Enter accepts the selected item (this is the key fix for "line skip" issue)
        ['<CR>'] = { 'accept', 'fallback' },
      })

      opts.completion = vim.tbl_deep_extend('force', opts.completion or {}, {
        trigger = {
          -- Show completion immediately when typing
          show_on_keyword = true,
          show_on_trigger_character = true,
        },
        list = {
          selection = {
            -- Preselect first item for quick Enter acceptance
            preselect = true,
            -- Don't auto-insert until explicitly accepted
            auto_insert = false,
          },
        },
        -- Disable ghost text (Supermaven provides inline suggestions)
        ghost_text = {
          enabled = false,
        },
        -- Auto-show documentation
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        -- Menu appearance
        menu = {
          draw = {
            columns = {
              { 'kind_icon' },
              { 'label', 'label_description', gap = 1 },
            },
          },
        },
        -- Accept behavior - insert on selection, replace on accept
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
      })

      -- Better signature help
      opts.signature = vim.tbl_deep_extend('force', opts.signature or {}, {
        enabled = true,
        window = {
          border = 'rounded',
        },
      })
    end,
  },
}
