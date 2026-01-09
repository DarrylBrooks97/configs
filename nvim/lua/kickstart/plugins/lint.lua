return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      -- Configure linters by filetype
      lint.linters_by_ft = {
        -- TypeScript/JavaScript - use eslint_d for speed
        javascript = { 'eslint_d' },
        javascriptreact = { 'eslint_d' },
        typescript = { 'eslint_d' },
        typescriptreact = { 'eslint_d' },
        -- JSON
        json = { 'jsonlint' },
        -- YAML
        yaml = { 'yamllint' },
        -- Dockerfile
        dockerfile = { 'hadolint' },
        -- Markdown
        markdown = { 'markdownlint' },
        -- Python
        python = { 'ruff' },
        -- Go
        go = { 'golangcilint' },
      }

      -- Custom eslint_d configuration to find config files
      lint.linters.eslint_d = require('lint').linters.eslint_d
      lint.linters.eslint_d.args = {
        '--format',
        'json',
        '--stdin',
        '--stdin-filename',
        function()
          return vim.api.nvim_buf_get_name(0)
        end,
      }

      -- Create autocommand which carries out the actual linting
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          -- Only run the linter in buffers that you can modify
          if vim.bo.modifiable then
            -- Check if eslint config exists for JS/TS files
            local ft = vim.bo.filetype
            if ft == 'javascript' or ft == 'javascriptreact' or ft == 'typescript' or ft == 'typescriptreact' then
              local eslint_config = vim.fn.findfile('.eslintrc.js', '.;')
                or vim.fn.findfile('.eslintrc.json', '.;')
                or vim.fn.findfile('.eslintrc.cjs', '.;')
                or vim.fn.findfile('eslint.config.js', '.;')
                or vim.fn.findfile('eslint.config.mjs', '.;')
                or vim.fn.findfile('eslint.config.cjs', '.;')

              -- Also check package.json for eslintConfig
              local package_json = vim.fn.findfile('package.json', '.;')
              if package_json ~= '' and eslint_config == '' then
                local content = vim.fn.readfile(package_json)
                local json_str = table.concat(content, '\n')
                if json_str:find '"eslintConfig"' then
                  eslint_config = package_json
                end
              end

              if eslint_config ~= '' then
                lint.try_lint()
              end
            else
              lint.try_lint()
            end
          end
        end,
      })

      -- Keymap to manually trigger linting
      vim.keymap.set('n', '<leader>cl', function()
        lint.try_lint()
      end, { desc = '[C]ode [L]int' })
    end,
  },
}
