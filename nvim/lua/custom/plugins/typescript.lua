-- Comprehensive TypeScript/JavaScript development setup
-- Provides enhanced navigation, refactoring, and IDE-like features

return {
  -- typescript-tools.nvim: Native TypeScript LSP integration (faster than ts_ls)
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
    opts = {
      -- Disable verbose logging (was causing performance issues)
      tsserver_logs = 'off',
      settings = {
        -- Spawn additional tsserver for projects with more than 200 files
        separate_diagnostic_server = true,
        -- Publish diagnostics on insert leave (less aggressive than on change)
        publish_diagnostic_on = 'insert_leave',
        -- Only expose specific code actions (reduces overhead)
        expose_as_code_action = { 'fix_all', 'add_missing_imports', 'remove_unused' },
        -- tsserver settings
        tsserver_path = nil,
        tsserver_plugins = {},
        -- Reduced memory limit (4GB is plenty, 8GB was excessive)
        tsserver_max_memory = 4096,
        tsserver_format_options = {},
        tsserver_file_preferences = {
          -- Inlay hints off by default (toggle with <leader>th) - reduces CPU usage
          includeInlayParameterNameHints = 'none',
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = false,
          includeInlayVariableTypeHints = false,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = false,
          includeInlayFunctionLikeReturnTypeHints = false,
          includeInlayEnumMemberValueHints = false,
          includeCompletionsForModuleExports = true,
          quotePreference = 'auto',
        },
        -- Code lens off (reduces CPU usage)
        code_lens = 'off',
        disable_member_code_lens = true,
        -- Complete function calls (adds parentheses)
        complete_function_calls = true,
        -- JSX close tag
        jsx_close_tag = {
          enable = true,
          filetypes = { 'javascriptreact', 'typescriptreact' },
        },
      },
    },
    config = function(_, opts)
      require('typescript-tools').setup(opts)

      -- TypeScript-specific keymaps (only active in TS/JS files)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'TS: ' .. desc })
          end

          -- Organize imports
          map('<leader>to', '<cmd>TSToolsOrganizeImports<cr>', '[O]rganize Imports')

          -- Sort imports
          map('<leader>ts', '<cmd>TSToolsSortImports<cr>', '[S]ort Imports')

          -- Remove unused imports
          map('<leader>tu', '<cmd>TSToolsRemoveUnusedImports<cr>', 'Remove [U]nused Imports')

          -- Remove unused statements (variables, etc.)
          map('<leader>tx', '<cmd>TSToolsRemoveUnused<cr>', 'Remove Unused Statements')

          -- Add missing imports
          map('<leader>ti', '<cmd>TSToolsAddMissingImports<cr>', 'Add Missing [I]mports')

          -- Fix all auto-fixable issues
          map('<leader>tf', '<cmd>TSToolsFixAll<cr>', '[F]ix All')

          -- Go to source definition (skips .d.ts files)
          map('<leader>tD', '<cmd>TSToolsGoToSourceDefinition<cr>', 'Go to Source [D]efinition')

          -- Rename file and update imports
          map('<leader>tR', '<cmd>TSToolsRenameFile<cr>', '[R]ename File')

          -- File references (where is this file imported)
          map('<leader>tr', '<cmd>TSToolsFileReferences<cr>', 'File [R]eferences')

          -- TypeScript type checking (runs tsc --noEmit)
          map('<leader>tt', function()
            local root = vim.fn.getcwd()
            -- Check for tsconfig.json to find project root
            local tsconfig = vim.fn.findfile('tsconfig.json', root .. ';')
            if tsconfig ~= '' then
              root = vim.fn.fnamemodify(tsconfig, ':h')
            end
            vim.cmd('compiler tsc')
            vim.cmd('setlocal makeprg=npx\\ tsc\\ --noEmit\\ -p\\ ' .. vim.fn.fnameescape(root))
            vim.cmd('make!')
            vim.cmd('copen')
          end, '[T]ype Check (tsc)')
        end,
      })
    end,
  },


  -- nvim-treesitter-textobjects: Enhanced text objects for code navigation
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    event = 'VeryLazy',
    config = function()
      require('nvim-treesitter.configs').setup {
        textobjects = {
          -- Select text objects
          select = {
            enable = true,
            lookahead = true, -- Jump forward to matching text object
            keymaps = {
              -- Function text objects
              ['af'] = { query = '@function.outer', desc = 'Select outer function' },
              ['if'] = { query = '@function.inner', desc = 'Select inner function' },
              -- Class text objects
              ['ac'] = { query = '@class.outer', desc = 'Select outer class' },
              ['ic'] = { query = '@class.inner', desc = 'Select inner class' },
              -- Parameter/argument text objects
              ['aa'] = { query = '@parameter.outer', desc = 'Select outer argument' },
              ['ia'] = { query = '@parameter.inner', desc = 'Select inner argument' },
              -- Conditional text objects
              ['ai'] = { query = '@conditional.outer', desc = 'Select outer conditional' },
              ['ii'] = { query = '@conditional.inner', desc = 'Select inner conditional' },
              -- Loop text objects
              ['al'] = { query = '@loop.outer', desc = 'Select outer loop' },
              ['il'] = { query = '@loop.inner', desc = 'Select inner loop' },
              -- Block text objects (useful for JSX)
              ['ab'] = { query = '@block.outer', desc = 'Select outer block' },
              ['ib'] = { query = '@block.inner', desc = 'Select inner block' },
              -- Comment text objects
              ['aC'] = { query = '@comment.outer', desc = 'Select outer comment' },
              ['iC'] = { query = '@comment.inner', desc = 'Select inner comment' },
              -- Call (function call) text objects
              ['am'] = { query = '@call.outer', desc = 'Select outer call' },
              ['im'] = { query = '@call.inner', desc = 'Select inner call' },
            },
          },
          -- Move between text objects
          move = {
            enable = true,
            set_jumps = true, -- Add jumps to jumplist
            goto_next_start = {
              [']f'] = { query = '@function.outer', desc = 'Next function start' },
              [']c'] = { query = '@class.outer', desc = 'Next class start' },
              [']a'] = { query = '@parameter.inner', desc = 'Next argument' },
              [']i'] = { query = '@conditional.outer', desc = 'Next conditional' },
              [']l'] = { query = '@loop.outer', desc = 'Next loop' },
              [']m'] = { query = '@call.outer', desc = 'Next function call' },
            },
            goto_next_end = {
              [']F'] = { query = '@function.outer', desc = 'Next function end' },
              [']C'] = { query = '@class.outer', desc = 'Next class end' },
            },
            goto_previous_start = {
              ['[f'] = { query = '@function.outer', desc = 'Previous function start' },
              ['[c'] = { query = '@class.outer', desc = 'Previous class start' },
              ['[a'] = { query = '@parameter.inner', desc = 'Previous argument' },
              ['[i'] = { query = '@conditional.outer', desc = 'Previous conditional' },
              ['[l'] = { query = '@loop.outer', desc = 'Previous loop' },
              ['[m'] = { query = '@call.outer', desc = 'Previous function call' },
            },
            goto_previous_end = {
              ['[F'] = { query = '@function.outer', desc = 'Previous function end' },
              ['[C'] = { query = '@class.outer', desc = 'Previous class end' },
            },
          },
          -- Swap arguments/parameters
          swap = {
            enable = true,
            swap_next = {
              ['<leader>wa'] = { query = '@parameter.inner', desc = 'Swap with next argument' },
              ['<leader>wf'] = { query = '@function.outer', desc = 'Swap with next function' },
            },
            swap_previous = {
              ['<leader>wA'] = { query = '@parameter.inner', desc = 'Swap with previous argument' },
              ['<leader>wF'] = { query = '@function.outer', desc = 'Swap with previous function' },
            },
          },
          -- Peek at definition (show in floating window)
          lsp_interop = {
            enable = true,
            border = 'rounded',
            peek_definition_code = {
              ['<leader>pf'] = { query = '@function.outer', desc = 'Peek function definition' },
              ['<leader>pc'] = { query = '@class.outer', desc = 'Peek class definition' },
            },
          },
        },
      }

      -- Repeat movement with ; and ,
      local ts_repeat_move = require 'nvim-treesitter.textobjects.repeatable_move'
      vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move_next)
      vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_previous)
    end,
  },

  -- nvim-treesitter-context: Show code context at top of screen
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = 'VeryLazy',
    opts = {
      enable = true,
      max_lines = 3,
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 20,
      trim_scope = 'outer',
      mode = 'cursor',
      separator = nil,
      zindex = 20,
    },
    keys = {
      {
        '<leader>tc',
        function()
          require('treesitter-context').toggle()
        end,
        desc = 'Toggle [C]ontext',
      },
      {
        '[C',
        function()
          require('treesitter-context').go_to_context()
        end,
        desc = 'Jump to context',
      },
    },
  },

  -- Telescope extensions for better symbol navigation
  {
    'nvim-telescope/telescope.nvim',
    keys = {
      -- Quick access to document symbols (great for navigating TS files)
      { '<leader>so', '<cmd>Telescope lsp_document_symbols<cr>', desc = '[S]earch Document Symbols' },
      -- Workspace symbols
      { '<leader>sO', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>', desc = '[S]earch Workspace Symbols' },
      -- Incoming/outgoing calls
      { '<leader>si', '<cmd>Telescope lsp_incoming_calls<cr>', desc = '[S]earch [I]ncoming Calls' },
      { '<leader>sI', '<cmd>Telescope lsp_outgoing_calls<cr>', desc = '[S]earch Outgoing Calls' },
    },
  },

  -- Trouble.nvim: Better diagnostics and quickfix list
  {
    'folke/trouble.nvim',
    cmd = { 'Trouble' },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      position = 'bottom',
      height = 15,
      padding = true,
      auto_preview = true,
      auto_fold = false,
      use_diagnostic_signs = true,
    },
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics (Trouble)' },
      { '<leader>xs', '<cmd>Trouble symbols toggle focus=false<cr>', desc = 'Symbols (Trouble)' },
      {
        '<leader>xl',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        desc = 'LSP Definitions/References (Trouble)',
      },
      { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = 'Location List (Trouble)' },
      { '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix List (Trouble)' },
      {
        '[q',
        function()
          if require('trouble').is_open() then
            require('trouble').prev { skip_groups = true, jump = true }
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = 'Previous Trouble/Quickfix Item',
      },
      {
        ']q',
        function()
          if require('trouble').is_open() then
            require('trouble').next { skip_groups = true, jump = true }
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = 'Next Trouble/Quickfix Item',
      },
    },
  },

  -- flash.nvim: Lightning fast navigation (replaces leap/hop)
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      labels = 'asdfghjklqwertyuiopzxcvbnm',
      search = { mode = 'exact' },
      label = { after = false, before = true, style = 'overlay' },
      modes = {
        char = { enabled = true, jump_labels = true },
        search = { enabled = false }, -- don't hijack / search
      },
    },
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash jump' },
      { 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash Treesitter' },
      { 'r', mode = 'o', function() require('flash').remote() end, desc = 'Remote Flash' },
      { 'R', mode = { 'o', 'x' }, function() require('flash').treesitter_search() end, desc = 'Treesitter Search' },
    },
  },

  -- harpoon: Quick file switching (mark files, jump instantly)
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup {
        settings = {
          save_on_toggle = true,
          sync_on_ui_close = true,
        },
      }

      -- Keymaps for harpoon
      vim.keymap.set('n', '<leader>ha', function() harpoon:list():add() end, { desc = 'Harpoon: Add file' })
      vim.keymap.set('n', '<leader>hh', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon: Menu' })

      -- Quick jump to harpooned files (1-5)
      vim.keymap.set('n', '<leader>1', function() harpoon:list():select(1) end, { desc = 'Harpoon: File 1' })
      vim.keymap.set('n', '<leader>2', function() harpoon:list():select(2) end, { desc = 'Harpoon: File 2' })
      vim.keymap.set('n', '<leader>3', function() harpoon:list():select(3) end, { desc = 'Harpoon: File 3' })
      vim.keymap.set('n', '<leader>4', function() harpoon:list():select(4) end, { desc = 'Harpoon: File 4' })
      vim.keymap.set('n', '<leader>5', function() harpoon:list():select(5) end, { desc = 'Harpoon: File 5' })

      -- Navigate through harpoon list
      vim.keymap.set('n', '<C-S-P>', function() harpoon:list():prev() end, { desc = 'Harpoon: Previous' })
      vim.keymap.set('n', '<C-S-N>', function() harpoon:list():next() end, { desc = 'Harpoon: Next' })
    end,
  },

  -- outline.nvim: Symbol outline sidebar
  {
    'hedyhli/outline.nvim',
    cmd = { 'Outline', 'OutlineOpen' },
    keys = {
      { '<leader>o', '<cmd>Outline<cr>', desc = 'Toggle Outline' },
    },
    opts = {
      outline_window = {
        position = 'right',
        width = 25,
        relative_width = true,
        auto_close = false,
        auto_jump = false,
        show_numbers = false,
        show_relative_numbers = false,
        wrap = false,
      },
      symbols = {
        filter = {
          default = { 'String', exclude = true },
          javascript = { 'Function', 'Class', 'Method', 'Constructor', 'Interface', 'Variable' },
          typescript = { 'Function', 'Class', 'Method', 'Constructor', 'Interface', 'Variable', 'TypeAlias' },
        },
      },
      symbol_folding = {
        autofold_depth = 1,
        auto_unfold_hover = true,
      },
    },
  },

  -- nvim-navic + barbecue: Breadcrumb navigation in winbar
  {
    'SmiteshP/nvim-navic',
    lazy = true,
    opts = {
      lsp = { auto_attach = true },
      highlight = true,
      depth_limit = 5,
    },
  },
  {
    'utilyre/barbecue.nvim',
    name = 'barbecue',
    version = '*',
    dependencies = { 'SmiteshP/nvim-navic', 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = {
      attach_navic = false, -- navic attaches itself
      show_dirname = false,
      show_basename = true,
    },
  },

  -- which-key: Add navigation groups
  {
    'folke/which-key.nvim',
    opts = {
      spec = {
        { '<leader>t', group = '[T]ypeScript' },
        { '<leader>p', group = '[P]eek' },
        { '<leader>w', group = 'S[w]ap' },
        { '<leader>x', group = 'Trouble' },
        { '<leader>h', group = '[H]arpoon' },
      },
    },
  },

  -- Supermaven: Lightning-fast AI autocomplete (free tier available)
  {
    'supermaven-inc/supermaven-nvim',
    event = 'InsertEnter',
    config = function()
      require('supermaven-nvim').setup {
        keymaps = {
          accept_suggestion = '<Tab>',
          clear_suggestion = '<C-]>',
          accept_word = '<C-j>',
        },
        ignore_filetypes = { 'TelescopePrompt' },
        color = {
          suggestion_color = '#585858',
          cterm = 244,
        },
        log_level = 'off',
        disable_inline_completion = false,
        disable_keymaps = false,
      }
    end,
  },

  -- vim-illuminate: Highlight other occurrences of word under cursor
  {
    'RRethy/vim-illuminate',
    event = 'VeryLazy',
    config = function()
      require('illuminate').configure {
        providers = { 'lsp', 'treesitter', 'regex' },
        delay = 100,
        filetypes_denylist = { 'NvimTree', 'neo-tree', 'Trouble', 'Outline', 'TelescopePrompt' },
        under_cursor = true,
        large_file_cutoff = 2000,
        large_file_overrides = { providers = { 'lsp' } },
      }

      -- Keymaps to navigate between references
      vim.keymap.set('n', ']]', function() require('illuminate').goto_next_reference(false) end, { desc = 'Next reference' })
      vim.keymap.set('n', '[[', function() require('illuminate').goto_prev_reference(false) end, { desc = 'Prev reference' })
    end,
  },

  -- todo-comments: Highlight TODO, FIXME, NOTE, etc in comments
  {
    'folke/todo-comments.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      signs = true,
      sign_priority = 8,
      keywords = {
        FIX = { icon = ' ', color = 'error', alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE' } },
        TODO = { icon = ' ', color = 'info' },
        HACK = { icon = ' ', color = 'warning' },
        WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'XXX' } },
        PERF = { icon = ' ', alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' } },
        NOTE = { icon = ' ', color = 'hint', alt = { 'INFO' } },
        TEST = { icon = '⏲ ', color = 'test', alt = { 'TESTING', 'PASSED', 'FAILED' } },
      },
      highlight = {
        multiline = true,
        before = '',
        keyword = 'wide',
        after = 'fg',
        pattern = [[.*<(KEYWORDS)\s*:]],
        comments_only = true,
      },
    },
    keys = {
      { ']t', function() require('todo-comments').jump_next() end, desc = 'Next TODO' },
      { '[t', function() require('todo-comments').jump_prev() end, desc = 'Prev TODO' },
      { '<leader>st', '<cmd>TodoTelescope<cr>', desc = '[S]earch [T]ODOs' },
      { '<leader>xt', '<cmd>Trouble todo<cr>', desc = 'TODOs (Trouble)' },
    },
  },
}
