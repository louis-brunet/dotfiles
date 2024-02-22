---@type LazySpec
local M = {
    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',

    -- Useful plugin to show pending keybinds.
    { 'folke/which-key.nvim', event = 'VeryLazy', opts = {} },

    {
        -- Add indentation guides even on blank lines
        'lukas-reineke/indent-blankline.nvim',
        -- Enable `lukas-reineke/indent-blankline.nvim`
        -- See `:help indent_blankline.txt`
        event = 'VeryLazy',
        main = 'ibl',
        opts = {
            indent = {
                char = '▏',
                -- char = '┊',
            },
            scope = {
                enabled = true,
            },
            -- whitespace = {
            --     remove_blankline_trail = true,
            -- },
        },
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
        },
    },

    -- Automatically change normal strings to template strings
    {
        'axelvc/template-string.nvim',
        event = 'VeryLazy',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        opts = {
            filetypes = { -- filetypes where the plugin is active
                -- 'html',
                'typescript',
                'javascript',
                'typescriptreact',
                'javascriptreact',
                'python',
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
        event = 'VeryLazy',
        ---@type CommentConfig
        opts = {
            -- DEFAULTS:
            -- padding = true,
            -- sticky = true,
            -- ignore = nil,
            toggler = { line = 'gcc', block = 'gbc' },
            opleader = { line = 'gc', block = 'gb' },
            -- toggler = { line = '<leader>cc', block = 'gbc' },
            -- opleader = { line = '<leader>c', block = 'gb' },
            -- extra = { above = 'gcO', below = 'gco', eol = 'gcA' },
            -- mappings = { basic = true, extra = true },
            -- pre_hook = nil,
            -- post_hook = nil,
        },
        -- keys = {
        --     { '<leader>cc', '<Plug>(comment_toggle_linewise_current)', mode = 'n', desc = '[C]omment toggle linewise' },
        --     { '<leader>c',  '<Plug>(comment_toggle_linewise_visual)',  mode = 'v', desc = '[C]omment toggle linewise' },
        -- },
        config = function(_, opts)
            require('Comment').setup(opts)

            -- add commentstring for pug templating engine
            require('Comment.ft').set('pug', '// %s')

            vim.keymap.set('n', '<leader>cc', '<Plug>(comment_toggle_linewise_current)',
                { desc = '[C]omment toggle linewise' })
            vim.keymap.set('v', '<leader>c', '<Plug>(comment_toggle_linewise_visual)',
                { desc = '[C]omment toggle linewise' })
        end
    },

    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        opts = {
            -- Configuration here, or leave empty to use defaults
            keymaps = {
                -- insert = "<C-g>s",
                -- insert_line = "<C-g>S",
                -- normal = "ys",
                -- normal_cur = "yss",
                -- normal_line = "yS",
                -- normal_cur_line = "ySS",
                -- visual = "S",
                -- visual_line = "gS",
                -- delete = "ds",
                -- change = "cs",
                -- change_line = "cS",
            },
            -- highlight = {
            --     duration = 200,
            -- },
        },
        -- config = function(_, opts)
        --     require("nvim-surround").setup(opts)
        -- end
    },

    -- highlight and search for todo comments like TODO, HACK, BUG, FIXME, WARN ...
    {
        'folke/todo-comments.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {
            -- DEFAULTS:
            -- signs = true,          -- show icons in the signs column
            -- sign_priority = 8,     -- sign priority
            -- -- keywords recognized as todo comments
            -- keywords = {
            --     FIX = {
            --         icon = " ", -- icon used for the sign, and in search results
            --         color = "error", -- can be a hex color, or a named color (see below)
            --         alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
            --         -- signs = false, -- configure signs for some keywords individually
            --     },
            --     TODO = { icon = " ", color = "info" },
            --     HACK = { icon = " ", color = "warning" },
            --     WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
            --     PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
            --     NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
            --     TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
            -- },
            -- gui_style = {
            --     fg = "NONE",           -- The gui style to use for the fg highlight group.
            --     bg = "BOLD",           -- The gui style to use for the bg highlight group.
            -- },
            -- merge_keywords = true,     -- when true, custom keywords will be merged with the defaults
            -- -- highlighting of the line containing the todo comment
            -- -- * before: highlights before the keyword (typically comment characters)
            -- -- * keyword: highlights of the keyword
            -- -- * after: highlights after the keyword (todo text)
            -- highlight = {
            --     multiline = true,                    -- enable multine todo comments
            --     multiline_pattern = "^.",            -- lua pattern to match the next multiline from the start of the matched keyword
            --     multiline_context = 10,              -- extra lines that will be re-evaluated when changing a line
            --     before = "",                         -- "fg" or "bg" or empty
            --     keyword = "wide",                    -- "fg", "bg", "wide", "wide_bg", "wide_fg" or empty. (wide and wide_bg is the same as bg, but will also highlight surrounding characters, wide_fg acts accordingly but with fg)
            --     after = "fg",                        -- "fg" or "bg" or empty
            --     pattern = [[.*<(KEYWORDS)\s*:]],     -- pattern or table of patterns, used for highlighting (vim regex)
            --     comments_only = true,                -- uses treesitter to match keywords in comments only
            --     max_line_len = 400,                  -- ignore lines longer than this
            --     exclude = {},                        -- list of file types to exclude highlighting
            -- },
            -- -- list of named colors where we try to extract the guifg from the
            -- -- list of highlight groups or use the hex color if hl not found as a fallback
            -- colors = {
            --     error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
            --     warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
            --     info = { "DiagnosticInfo", "#2563EB" },
            --     hint = { "DiagnosticHint", "#10B981" },
            --     default = { "Identifier", "#7C3AED" },
            --     test = { "Identifier", "#FF00FF" }
            -- },
            -- search = {
            --     command = "rg",
            --     args = {
            --         "--color=never",
            --         "--no-heading",
            --         "--with-filename",
            --         "--line-number",
            --         "--column",
            --     },
            --     -- regex that will be used to match keywords.
            --     -- don't replace the (KEYWORDS) placeholder
            --     pattern = [[\b(KEYWORDS):]],     -- ripgrep regex
            --     -- pattern = [[\b(KEYWORDS)\b]], -- match without the extra colon. You'll likely get false positives
            -- },
        },
    },
}

return M
