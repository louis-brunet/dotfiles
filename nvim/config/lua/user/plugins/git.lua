--- [ Git related plugins ]
---@type LazySpec
local M = {
    {
        'tpope/vim-fugitive',

        -- Load immediately to enable `nvim -c 'Git mergetool'`
        lazy = false,

        -- event = 'VeryLazy',

        keys = {
            { '<leader>gmt', function() vim.cmd 'Git mergetool -y' end, desc = '[G]it [m]erge[t]ool' },
        },
    },

    -- GitHub integration
    -- 'tpope/vim-rhubarb',

    {
        -- Adds git related signs to the gutter, as well as utilities for managing changes
        'lewis6991/gitsigns.nvim',
        event = 'VeryLazy',
        opts = {
            -- See `:help gitsigns.txt`
            signs = {
                -- add = { text = '+' },
                -- change = { text = '~' },
                -- delete = { text = '_' },
                -- topdelete = { text = '‾' },
                -- changedelete = { text = '~' },
            },

            -- Executed when attaching to new git file
            on_attach = function(bufnr)
                local function nmap(lhs, rhs, desc)
                    vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
                end

                -- Gitsigns mappings
                nmap('<leader>gp', function() require('gitsigns').prev_hunk() end, '[G]it: [P]revious Hunk')
                nmap('[g', function() require('gitsigns').prev_hunk() end, '[G]it: Previous Hunk')

                nmap('<leader>gn', function() require('gitsigns').next_hunk() end, '[G]it: [N]ext Hunk')
                nmap(']g', function() require('gitsigns').next_hunk() end, '[G]it: Next Hunk')

                nmap('<leader>gr', function() require('gitsigns').reset_hunk() end, '[G]it: [R]eset Hunk')
                nmap('<leader>gh', function() require('gitsigns').preview_hunk_inline() end, '[G]it: Preview [H]unk')


                -- Other mappings only used in a git buffer
                -- nmap(...)
            end,
        },
    },
}

return M
