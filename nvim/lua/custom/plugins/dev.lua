return {
  -- LSP servers and settings
  {
    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = vim.tbl_extend('force', opts.servers or {}, {
        vtsls = {
          settings = {
            typescript = {
              inlayHints = {
                parameterNames = { enabled = 'literals' },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
            javascript = {
              inlayHints = {
                parameterNames = { enabled = 'literals' },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
          },
        },
        tailwindcss = {},
        html = {},
        cssls = {},
        jsonls = {},
        emmet_ls = {},
        basedpyright = {},
        ruff_lsp = {},
        gopls = {},
        yamlls = {},
        dockerls = {},
        bashls = {},
        lua_ls = {},
      })
      return opts
    end,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    opts = function(_, opts)
      opts = opts or {}
      local ensure = {
        'vtsls',
        'tailwindcss',
        'html',
        'cssls',
        'jsonls',
        'emmet_ls',
        'basedpyright',
        'ruff_lsp',
        'gopls',
        'yamlls',
        'dockerls',
        'bashls',
        'lua_ls',
      }
      opts.ensure_installed = vim.tbl_extend('force', opts.ensure_installed or {}, ensure)
      return opts
    end,
  },

  -- Treesitter languages
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts = opts or {}
      local langs = {
        'javascript',
        'typescript',
        'tsx',
        'json',
        'css',
        'html',
        'go',
        'gomod',
        'gosum',
        'gowork',
        'python',
        'bash',
        'yaml',
        'dockerfile',
        'markdown',
        'markdown_inline',
        'lua',
        'vim',
        'vimdoc',
        'query',
      }
      opts.ensure_installed = vim.tbl_extend('force', opts.ensure_installed or {}, langs)
      return opts
    end,
  },

  -- Formatting (Conform)
  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      opts = opts or {}
      opts.format_on_save = { timeout_ms = 1500, lsp_fallback = true }
      opts.formatters_by_ft = vim.tbl_extend('force', opts.formatters_by_ft or {}, {
        javascript = { 'prettierd', 'prettier' },
        typescript = { 'prettierd', 'prettier' },
        javascriptreact = { 'prettierd', 'prettier' },
        typescriptreact = { 'prettierd', 'prettier' },
        json = { 'prettierd', 'prettier' },
        jsonc = { 'prettierd', 'prettier' },
        css = { 'prettierd', 'prettier' },
        html = { 'prettierd', 'prettier' },
        markdown = { 'prettierd', 'prettier' },
        yaml = { 'prettierd', 'prettier' },
        python = { 'ruff_format', 'black' },
        go = { 'goimports', 'gofumpt' },
        sh = { 'shfmt' },
      })
      return opts
    end,
  },

  -- Linting (nvim-lint) - this plugin has no setup(), so configure manually
  {
    'mfussenegger/nvim-lint',
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        javascript = { 'eslint_d' },
        typescript = { 'eslint_d' },
        javascriptreact = { 'eslint_d' },
        typescriptreact = { 'eslint_d' },
        python = { 'ruff' },
        go = { 'golangcilint' },
        dockerfile = { 'hadolint' },
        yaml = { 'yamllint' },
      }

    end,
  },

  {
    'sphamba/smear-cursor.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'fast',
      cursor_color = 'none',
    },
  },

  -- Debugging stack
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',
      'jay-babu/mason-nvim-dap.nvim',
      'mxsdev/nvim-dap-vscode-js',
      'mfussenegger/nvim-dap-python',
      'leoluz/nvim-dap-go',
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'
      dapui.setup()
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      require('mason-nvim-dap').setup {
        ensure_installed = { 'js-debug-adapter', 'debugpy', 'delve' },
        automatic_installation = true,
        handlers = {},
      }

      -- Robust setup for vscode-js debug adapter, handling registry refresh and fallback path
      local function configure_js_debug()
        local registry = require 'mason-registry'
        local function do_setup(pkg)
          local path = (pkg and pkg.get_install_path and pkg:get_install_path()) or (vim.fn.stdpath 'data' .. '/mason/packages/js-debug-adapter')
          require('dap-vscode-js').setup {
            debugger_path = path,
            adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
          }
          for _, language in ipairs { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' } do
            dap.configurations[language] = {
              {
                type = 'pwa-node',
                request = 'launch',
                name = 'Launch file',
                program = '${file}',
                cwd = '${workspaceFolder}',
                sourceMaps = true,
                skipFiles = { '<node_internals>/**', 'node_modules/**' },
              },
              {
                type = 'pwa-node',
                request = 'attach',
                name = 'Attach to process',
                processId = require('dap.utils').pick_process,
                cwd = '${workspaceFolder}',
                skipFiles = { '<node_internals>/**', 'node_modules/**' },
              },
              {
                type = 'pwa-chrome',
                request = 'launch',
                name = 'Launch Chrome (Next.js)',
                url = 'http://localhost:3000',
                webRoot = '${workspaceFolder}',
                userDataDir = '${workspaceFolder}/.vscode/vscode-chrome-debug',
              },
            }
          end
        end
        local ok_pkg, pkg = pcall(registry.get_package, 'js-debug-adapter')
        if not ok_pkg or not pkg then
          registry.refresh(function()
            local p = registry.get_package 'js-debug-adapter'
            do_setup(p)
          end)
        else
          do_setup(pkg)
        end
      end
      configure_js_debug()

      -- Python debug: find debugpy install path robustly
      local function configure_python_debug()
        local registry = require 'mason-registry'
        local function do_setup(pkg)
          local python_path = (pkg and pkg.get_install_path and (pkg:get_install_path() .. '/venv/bin/python'))
            or (vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python')
          require('dap-python').setup(python_path)
        end
        local ok_pkg, pkg = pcall(registry.get_package, 'debugpy')
        if not ok_pkg or not pkg then
          registry.refresh(function()
            local p = registry.get_package 'debugpy'
            do_setup(p)
          end)
        else
          do_setup(pkg)
        end
      end
      configure_python_debug()

      require('dap-go').setup()
    end,
  },
}
