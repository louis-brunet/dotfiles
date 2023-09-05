---@type LazySpec
local M = {
    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',

    -- Useful plugin to show pending keybinds.
    { 'folke/which-key.nvim', opts = {} },

    {
        -- Add indentation guides even on blank lines
        'lukas-reineke/indent-blankline.nvim',
        -- Enable `lukas-reineke/indent-blankline.nvim`
        -- See `:help indent_blankline.txt`
        opts = {
            char = '┊',
            show_trailing_blankline_indent = false,
            use_treesitter = true,
        },
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
        },
    },

    {
        'axelvc/template-string.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        opts = {
            filetypes = { -- filetypes where the plugin is active
                -- 'html',
                'typescript',
                'javascript',
                'typescriptreact',
                'javascriptreact',
                -- 'python',
            },
            jsx_brackets = true,            -- must add brackets to jsx attributes
            remove_template_string = false, -- remove backticks when there are no template string
            restore_quotes = {
                -- quotes used when "remove_template_string" option is enabled
                normal = [[']],
                jsx = [[']],
            },
        },
    },

    -- "gc" to comment visual regions/lines
    {
        'numToStr/Comment.nvim',
        ---@type CommentConfig
        opts = {
            -- DEFAULTS:
            -- padding = true,
            -- sticky = true,
            -- ignore = nil,
            -- toggler = { line = 'gcc', block = 'gbc' },
            -- opleader = { line = 'gc', block = 'gb' },
            -- extra = { above = 'gcO', below = 'gco', eol = 'gcA' },
            -- mappings = { basic = true, extra = true },
            -- pre_hook = nil,
            -- post_hook = nil,
        },
        keys = {
            { '<leader>cc', '<Plug>(comment_toggle_linewise_current)', mode = 'n', desc = '[C]omment toggle linewise' },
            { '<leader>c',  '<Plug>(comment_toggle_linewise_visual)',  mode = 'v', desc = '[C]omment toggle linewise' },
        },
        config = function(_, opts)
            require('Comment').setup(opts)

            -- add commentstring for pug templating engine
            require('Comment.ft').set('pug', '// %s')
        end
    },
}

return M
