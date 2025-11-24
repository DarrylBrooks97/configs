return {
  {
    'kdheepak/lazygit.nvim',
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    dependencies = { 'nvim-lua/plenary.nvim' },
    init = function()
      vim.g.lazygit_floating_window_use_plenary = 0
      vim.g.lazygit_floating_window_scaling_factor = 1.0
      vim.g.lazygit_use_neovim_remote = 1
    end,
    keys = {
      { '<leader>gg', '<cmd>LazyGit<CR>', desc = 'LazyGit (repo status)' },
      { '<leader>gL', '<cmd>LazyGitFilter<CR>', desc = 'LazyGit log (repo)' },
      { '<leader>gf', '<cmd>LazyGitFilterCurrentFile<CR>', desc = 'LazyGit log (file)' },
      { '<leader>gF', '<cmd>LazyGitCurrentFile<CR>', desc = 'LazyGit status (file)' },
    },
  },
}
