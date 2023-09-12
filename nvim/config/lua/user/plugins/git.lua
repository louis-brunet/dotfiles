---@type LazySpec
local M = {
    -- Git related plugins
    {
        'tpope/vim-fugitive',
        event='VeryLazy',
    },
    -- 'tpope/vim-rhubarb',

    {
        -- Adds git related signs to the gutter, as well as utilities for managing changes
        'lewis6991/gitsigns.nvim',
        event='VeryLazy',
        opts = {
            -- See `:help gitsigns.txt`
            signs = {
                -- add = { text = '+' },
                -- change = { text = '~' },
                -- delete = { text = '_' },
                -- topdelete = { text = '‾' },
                -- changedelete = { text = '~' },
            },
            on_attach = function(bufnr)
                vim.keymap.set('n', '<leader>gp', require('gitsigns').prev_hunk,
                    { buffer = bufnr, desc = '[G]it: [P]revious Hunk' })
                vim.keymap.set('n', '<leader>gn', require('gitsigns').next_hunk,
                    { buffer = bufnr, desc = '[G]it: [N]ext Hunk' })
                vim.keymap.set('n', '<leader>ph', require('gitsigns').preview_hunk_inline,
                    { buffer = bufnr, desc = 'Git: [P]review [H]unk' })
            end,
        },
    },
}

return M

