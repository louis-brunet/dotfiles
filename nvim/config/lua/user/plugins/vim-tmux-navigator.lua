return {
    {
        'christoomey/vim-tmux-navigator',
        on_attach = function()
            vim.keymap.set('n', '<C-h>', ':TmuxNavigateLeft<CR>', 'tmux-navigator: navigate left');
            vim.keymap.set('n', '<C-j>', ':TmuxNavigateDown<CR>', 'tmux-navigator: navigate down');
            vim.keymap.set('n', '<C-k>', ':TmuxNavigateUp<CR>', 'tmux-navigator: navigate up');
            vim.keymap.set('n', '<C-l>', ':TmuxNavigateRight<CR>', 'tmux-navigator: navigate right');
        end,
    },
}
