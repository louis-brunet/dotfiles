---@type LazySpec
return {
    -- Fuzzy Finder (files, lsp, etc)
    {
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',

        -- NOTE: Loading Telescope on VeryLazy does not handle keymaps pressed before
        -- nvim was initialized (e.g. `$ nvim<Enter><Space>sf` in terminal)
        -- event = 'VeryLazy',

        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-ui-select.nvim',

            -- Fuzzy Finder Algorithm which requires local dependencies to be built.
            -- Only load if `make` is available. Make sure you have the system
            -- requirements installed.
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                -- NOTE: If you are having trouble with this installation,
                --       refer to the README for telescope-fzf-native for more instructions.
                build = 'make',
                cond = function()
                    return vim.fn.executable 'make' == 1
                end,
            },
        },

        config = function()
            -- [[ Configure Telescope ]]
            -- See `:help telescope` and `:help telescope.setup()`
            local telescope = require 'telescope'
            local telescope_themes = require 'telescope.themes'
            local telescope_builtin = require 'telescope.builtin'
            local telescope_layout_strategies = require 'telescope.pickers.layout_strategies'

            local custom_layout_strategy = 'horizontal_merged'
            local default_layout_config = {
                width = 0.95,
                height = 0.95,
                prompt_position = 'top',
            }
            local border_chars_box = { '─', '│', '─', '│', '┌', '┐', '┘', '└' }
            local border_chars_merge_top = { '─', '│', '─', '│', '├', '┤', '┘', '└' }

            telescope_layout_strategies[custom_layout_strategy] =
                function(picker, max_columns, max_lines, layout_config)
                    local layout = telescope_layout_strategies.horizontal(picker, max_columns, max_lines, layout_config)

                    if layout.prompt then
                        -- layout.prompt.title = ''
                        layout.prompt.borderchars = border_chars_box
                    end

                    if layout.results then
                        layout.results.title = ''
                        layout.results.borderchars = border_chars_merge_top
                        layout.results.line = layout.results.line - 1
                        layout.results.height = layout.results.height + 1
                    end

                    if layout.preview then
                        -- layout.preview.title = ''
                        layout.preview.borderchars = border_chars_box
                    end

                    return layout
                end

            telescope.setup({
                extensions = {
                    ["ui-select"] = {
                        telescope_themes.get_cursor {
                            layout_config = {
                                height = 12,
                            },
                            borderchars = {
                                prompt = border_chars_box,
                                preview = border_chars_box,
                                results = border_chars_merge_top,
                            }
                            -- even more opts
                        }

                        -- pseudo code / specification for writing custom displays, like the one
                        -- for "codeactions"
                        -- specific_opts = {
                        --   [kind] = {
                        --     make_indexed = function(items) -> indexed_items, width,
                        --     make_displayer = function(widths) -> displayer
                        --     make_display = function(displayer) -> function(e)
                        --     make_ordinal = function(e) -> string
                        --   },
                        --   -- for example to disable the custom builtin "codeactions" display
                        --      do the following
                        --   codeactions = false,
                        -- }
                    },
                },

                defaults = {
                    layout_strategy = custom_layout_strategy,
                    -- border = false,
                    sorting_strategy = 'ascending',
                    path_display = {
                        -- shorten = {
                        --     len = 1,
                        --     exclude = { -2, -1 },
                        -- },
                        truncate = true,
                    },
                    -- see `:h telescope.defaults.layout_config`
                    layout_config = {
                        [custom_layout_strategy] = default_layout_config,
                        horizontal = default_layout_config,
                        vertical = default_layout_config,
                    },
                    mappings = {
                        -- i = {
                        --     ['<C-u>'] = false,
                        --     ['<C-d>'] = false,
                        -- },
                    },
                },
            })

            -- Enable telescope fzf native, if installed
            pcall(telescope.load_extension, 'fzf')

            -- Enable telescope extension for ui-select (lua/user/plugins/telescope-ui-select.nvim)
            pcall(telescope.load_extension, 'ui-select')

            -- pcall(telescope.load_extension, 'ollouma')

            pcall(telescope.load_extension, 'notify')

            -- See `:help telescope.builtin`
            vim.keymap.set('n', '<leader>?', telescope_builtin.oldfiles, { desc = '[?] Find recently opened files' })
            vim.keymap.set('n', '<leader><space>', telescope_builtin.buffers, { desc = '[ ] Find existing buffers' })
            vim.keymap.set('n', '<leader>/', telescope_builtin.current_buffer_fuzzy_find,
                { desc = '[/] Fuzzily search in current buffer' })

            vim.keymap.set('n', '<leader>gf', telescope_builtin.git_files, { desc = 'Search [g]it [f]iles' })
            vim.keymap.set('n', '<leader>gs', telescope_builtin.git_status, { desc = 'Search [g]it [s]tatus' })
            vim.keymap.set('n', '<leader>gb', telescope_builtin.git_branches, { desc = 'Search [g]it [b]ranches' })
            vim.keymap.set('n', '<leader>gc', telescope_builtin.git_commits, { desc = 'Search [g]it [c]ommits' })
            vim.keymap.set('n', '<leader>gC', telescope_builtin.git_bcommits,
                { desc = 'Search [g]it [C]ommits for current buffer' })

            vim.keymap.set('n', '<leader>sf', function()
                telescope_builtin.find_files({
                    hidden = false,
                    no_ignore = false,
                    no_ignore_parent = false,
                })
            end, { desc = '[s]earch [f]iles' })
            vim.keymap.set('n', '<leader>sF', function()
                telescope_builtin.find_files({
                    hidden = true,
                    no_ignore = true,
                    no_ignore_parent = true,
                })
            end, { desc = '[s]earch [F]iles (no ignore)' })

            vim.keymap.set('n', '<leader>sh', telescope_builtin.help_tags, { desc = '[s]earch [h]elp' })
            vim.keymap.set('n', '<leader>sw', telescope_builtin.grep_string,
                { desc = '[s]earch current [w]ord' })
            vim.keymap.set('n', '<leader>sg', function()
                telescope_builtin.live_grep({ additional_args = { '--hidden' } })
            end, { desc = '[s]earch by [g]rep' })
            vim.keymap.set('n', '<leader>sd', telescope_builtin.diagnostics,
                { desc = '[s]earch [d]iagnostics' })
            vim.keymap.set('n', '<leader>sr', telescope_builtin.resume, { desc = '[s]earch [r]esume' })
        end
    },
}
