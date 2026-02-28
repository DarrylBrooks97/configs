-- autopairs and auto-tag configuration
-- https://github.com/windwp/nvim-autopairs
-- https://github.com/windwp/nvim-ts-autotag

return {
  -- nvim-autopairs: Auto close brackets, quotes, etc.
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      local autopairs = require 'nvim-autopairs'
      local Rule = require 'nvim-autopairs.rule'
      local cond = require 'nvim-autopairs.conds'

      autopairs.setup {
        check_ts = true, -- Use treesitter for smarter pairing
        ts_config = {
          lua = { 'string' }, -- Don't add pairs in lua string treesitter nodes
          javascript = { 'template_string' },
          typescript = { 'template_string' },
          javascriptreact = { 'template_string', 'jsx_element' },
          typescriptreact = { 'template_string', 'jsx_element' },
        },
        disable_filetype = { 'TelescopePrompt', 'vim' },
        fast_wrap = {
          map = '<M-e>', -- Alt+e to wrap with pairs
          chars = { '{', '[', '(', '"', "'" },
          pattern = [=[[%'%"%)%>%]%)%}%,]]=],
          end_key = '$',
          keys = 'qwertyuiopzxcvbnmasdfghjkl',
          check_comma = true,
          highlight = 'Search',
          highlight_grey = 'Comment',
        },
        -- Enable moving past closing pairs with Tab
        enable_moveright = true,
        -- Don't add closing pair on same line if next char is alphanumeric
        enable_check_bracket_line = true,
        -- Ignore auto-pair when the cursor is inside these treesitter nodes
        ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
      }

      -- Add spaces between parentheses
      local brackets = { { '(', ')' }, { '[', ']' }, { '{', '}' } }
      autopairs.add_rules {
        -- Add space padding inside brackets
        Rule(' ', ' ')
          :with_pair(function(opts)
            local pair = opts.line:sub(opts.col - 1, opts.col)
            return vim.tbl_contains({
              brackets[1][1] .. brackets[1][2],
              brackets[2][1] .. brackets[2][2],
              brackets[3][1] .. brackets[3][2],
            }, pair)
          end)
          :with_move(cond.none())
          :with_cr(cond.none())
          :with_del(function(opts)
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local context = opts.line:sub(col - 1, col + 2)
            return vim.tbl_contains({
              brackets[1][1] .. '  ' .. brackets[1][2],
              brackets[2][1] .. '  ' .. brackets[2][2],
              brackets[3][1] .. '  ' .. brackets[3][2],
            }, context)
          end),
      }
      -- Move past commas and semicolons
      for _, punct in pairs { ',', ';' } do
        autopairs.add_rules {
          Rule('', punct)
            :with_move(function(opts)
              return opts.char == punct
            end)
            :with_pair(function()
              return false
            end)
            :with_del(function()
              return false
            end)
            :with_cr(function()
              return false
            end)
            :use_key(punct),
        }
      end

      -- Arrow function in JavaScript/TypeScript: () => {}
      autopairs.add_rules {
        Rule('%(.*%)%s*%=>$', ' {  }', { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' })
          :use_regex(true)
          :set_end_pair_length(2),
      }

      -- Better JSX angle bracket handling
      autopairs.add_rules {
        Rule('<', '>', { 'typescriptreact', 'javascriptreact' }):with_pair(cond.not_before_regex '%w'),
      }
    end,
  },

  -- nvim-ts-autotag: Auto close and rename HTML/JSX tags
  {
    'windwp/nvim-ts-autotag',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      opts = {
        -- Enable auto close
        enable_close = true,
        -- Enable auto rename
        enable_rename = true,
        -- Enable close on slash
        enable_close_on_slash = true,
      },
    },
  },

  -- mini.surround: Surround text with brackets, quotes, tags
  {
    'echasnovski/mini.surround',
    event = 'VeryLazy',
    opts = {
      mappings = {
        add = 'gsa', -- Add surrounding in Normal and Visual modes
        delete = 'gsd', -- Delete surrounding
        find = 'gsf', -- Find surrounding (to the right)
        find_left = 'gsF', -- Find surrounding (to the left)
        highlight = 'gsh', -- Highlight surrounding
        replace = 'gsr', -- Replace surrounding
        update_n_lines = 'gsn', -- Update `n_lines`
      },
    },
  },
}
