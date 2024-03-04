--- [ Git related plugins ]
---@type LazySpec
local M = {
    {
        'tpope/vim-fugitive',

        -- Load immediately to enable `nvim -c 'Git mergetool'`
        lazy = false,

        -- event = 'VeryLazy',

        keys = {
            { '<leader>gmt', function() vim.cmd 'Git mergetool -y' end, desc = '[g]it [m]erge[t]ool' },

            -- TODO: diffget keybinds, the handlers should check 
            --  1. how many buffers ?
            --  2. which layout ? (why different in desktop ~/code/test/mergeconflict vs neoxia ~/code/test/merge*_nobase ?)
            --
            -- assumes nvimdiff3 layout (LOCAL BASE REMOTE / MERGED), or (LOCAL MERGED REMOTE)
            { '<leader>gmh', function() vim.cmd.diffget(vim.fn.tabpagebuflist()[1]) end, desc = '[g]it [m]erge diffget left (LOCAL) ' },
            { '<leader>gmk', function() vim.cmd.diffget(vim.fn.tabpagebuflist()[2]) end, desc = '[g]it [m]erge diffget middle (BASE)' },
            { '<leader>gml', function() vim.cmd.diffget(vim.fn.tabpagebuflist()[3]) end, desc = '[g]it [m]erge diffget right (REMOTE)' },
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
                nmap('<leader>ghp', function() require('gitsigns').prev_hunk() end, '[g]it: [h]unk [p]revious')
                nmap('[g', function() require('gitsigns').prev_hunk() end, '[g]it: Previous Hunk')

                nmap('<leader>ghn', function() require('gitsigns').next_hunk() end, '[g]it: [h]unk [n]ext')
                nmap(']g', function() require('gitsigns').next_hunk() end, '[g]it: Next Hunk')

                nmap('<leader>ghr', function() require('gitsigns').reset_hunk() end, '[g]it: [h]unk [r]eset')
                nmap('<leader>ghh', function() require('gitsigns').preview_hunk_inline() end, '[g]it: Preview [h]unk')


                -- Other mappings only used in a git buffer
                -- nmap(...)
            end,
        },
    },
}

return M
