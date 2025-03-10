local function toggle_auto_pairs()
    vim.g.minipairs_disable = not vim.g.minipairs_disable
    if vim.g.minipairs_disable then
        vim.notify("disabled auto pairs", vim.log.levels.WARN,
            { title = "mini.pairs" })
        -- LazyVim.warn("Disabled auto pairs", { title = "Option" })
    else
        vim.notify("enabled auto pairs", vim.log.levels.INFO,
            { title = "mini.pairs" })
        -- LazyVim.info("Enabled auto pairs", { title = "Option" })
    end
end

local M = {
    -- auto pairs
    {
        "echasnovski/mini.pairs",
        event = "VeryLazy",
        opts = {
            mappings = {
                ["`"] = {
                    action = "closeopen",
                    pair = "``",
                    neigh_pattern = "[^\\`].",
                    register = { cr = false },
                },
            },
        },
        keys = {
            -- {
            --     "<leader>mp",
            --     toggle_auto_pairs,
            --     desc = "Toggle Auto Pairs",
            -- },
        },
        config = function(_, opts)
            vim.api.nvim_create_user_command("ToggleAutoPairs", toggle_auto_pairs,
                { desc = "Toggle Auto Pairs" })

            require("mini.pairs").setup(opts)
        end,
    },

    -- Detect tabstop and shiftwidth automatically
    "tpope/vim-sleuth",

    -- Useful plugin to show pending keybinds.
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        ---@type wk.Opts
        opts = {
            -- preset = "classic",
            keys = {
                -- FIXME: doesn't work on mac, even after unbinding Mission Control shortcuts
                scroll_down = "<c-Down>",  -- binding to scroll down inside the popup
                scroll_up = "<c-Up>",      -- binding to scroll up inside the popup
            },
            ---@type wk.Spec
            spec = {
                { "z",          group = "fold" },

                { "ys",         group = "[s]urround" },

                { "]",          group = "next" },

                { "[",          group = "previous" },

                { "<leader>H",  group = "[H]arpoon" },

                { "<leader>d",  group = "[d]ebug" },

                { "<leader>l",  group = "[l]sp" },

                { "<leader>g",  group = "[g]it" },
                { "<leader>gh", group = "[h]unk" },
                { "<leader>gm", group = "[m]erge" },
                { "<leader>gd", group = "[d]iff" },

                { "<leader>q",  group = "[q]uickfix" },

                { "<leader>r",  group = "[r]est-nvim" },

                { "<leader>s",  group = "[s]earch" },

                { "<leader>w",  group = "[w]orkspace" },
            },
        },
        config = function(_, opts)
            local wk = require("which-key")
            wk.setup(opts)
        end,
    },

    {
        -- Add indentation guides even on blank lines
        "lukas-reineke/indent-blankline.nvim",

        -- See `:help indent_blankline.txt`
        event = "VeryLazy",
        main = "ibl",
        opts = {
            indent = {
                char = "▏",
                -- char = '┊',
            },
            scope = { enabled = true, show_start = false, show_end = false },
            -- whitespace = {
            --     remove_blankline_trail = true,
            -- },
        },
        dependencies = { "nvim-treesitter/nvim-treesitter" },
    },

    -- Automatically change normal strings to template strings
    {
        "axelvc/template-string.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        opts = {
            filetypes = {  -- filetypes where the plugin is active
                -- 'html',
                "typescript",
                "javascript",
                "typescriptreact",
                "javascriptreact",
                "python",
            },
            jsx_brackets = true,             -- must add brackets to jsx attributes
            remove_template_string = false,  -- remove backticks when there are no template string
            restore_quotes = {
                -- quotes used when "remove_template_string" option is enabled
                normal = [[']],
                jsx = [[']],
            },
        },
    },

    -- "gc" to comment visual regions/lines
    {
        "numToStr/Comment.nvim",
        event = "VeryLazy",
        ---@type CommentConfig
        opts = {
            -- DEFAULTS:
            -- padding = true,
            -- sticky = true,
            -- ignore = nil,
            toggler = { line = "gcc", block = "gbc" },
            opleader = { line = "gc", block = "gb" },
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
            local comment = require("Comment")
            local comment_filetype = require("Comment.ft")

            comment.setup(opts)

            -- add commentstring for pug templating engine
            comment_filetype.set("pug", "// %s")
            comment_filetype.set("git_config", "# %s")

            vim.keymap.set(
                "n", "<leader>cc", "<Plug>(comment_toggle_linewise_current)",
                { desc = "[C]omment toggle linewise" }
            )
            vim.keymap.set(
                "v", "<leader>c", "<Plug>(comment_toggle_linewise_visual)",
                { desc = "[C]omment toggle linewise" }
            )
        end,
    },

    {
        "kylechui/nvim-surround",
        version = "*",  -- Use for stability; omit to use `main` branch for the latest features
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
        "folke/todo-comments.nvim",

        event = "VeryLazy",

        dependencies = { "nvim-lua/plenary.nvim" },

        -- :h todo-comments.nvim.txt
        opts = {},

        keys = {
            { "<leader>st", ":TodoTelescope<CR>", desc = "[s]earch [t]odos" },
        },

        cmd = { "TodoQuickfix", "TodoTelescope" },
    },

    {
        "mbbill/undotree",

        cmd = { "UndotreeToggle" },

        keys = {
            { "<leader>u", vim.cmd.UndotreeToggle, desc = "[u]ndotree toggle" },
        },
    },

    {
        "danymat/neogen",
        opts = { snippet_engine = "luasnip" },
        config = function(_, opts)
            require("neogen").setup(opts)
            vim.keymap.set("n", "<leader>ld", require("neogen").generate,
                { desc = "LSP: generate [d]ocstring" })
        end,
    },
}

return M
