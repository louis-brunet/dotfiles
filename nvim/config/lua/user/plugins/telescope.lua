---@type LazySpec
return {
    -- Fuzzy Finder (files, lsp, etc)
    {
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        -- Loading Telescope on VeryLazy does not handle keymaps pressed before
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

            telescope.setup {
                extensions = {
                    ["ui-select"] = {
                        telescope_themes.get_cursor {
                            layout_config = {
                                height = 12,
                            },
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
                    -- see `:h telescope.defaults.layout_config`
                    layout_config = {
                        horizontal = {
                            width = 0.9
                        },
                        vertical = {
                            width = 0.9
                        }
                    },
                    mappings = {
                        -- i = {
                        --     ['<C-u>'] = false,
                        --     ['<C-d>'] = false,
                        -- },
                    },
                },
            }

            -- Enable telescope fzf native, if installed
            pcall(telescope.load_extension, 'fzf')

            -- Enable telescope extension for ui-select (lua/user/plugins/telescope-ui-select.nvim)
            pcall(telescope.load_extension, 'ui-select')

            -- See `:help telescope.builtin`
            vim.keymap.set('n', '<leader>?', telescope_builtin.oldfiles,
                { desc = '[?] Find recently opened files' })
            vim.keymap.set('n', '<leader><space>', telescope_builtin.buffers,
                { desc = '[ ] Find existing buffers' })
            vim.keymap.set('n', '<leader>/', function()
                -- You can pass additional configuration to telescope to change theme, layout, etc.
                telescope_builtin.current_buffer_fuzzy_find(telescope_themes.get_dropdown {
                    layout_config = { width = 90 },
                    -- winblend = 10,
                    -- previewer = false,
                })
            end, { desc = '[/] Fuzzily search in current buffer' })

            vim.keymap.set('n', '<leader>gf', telescope_builtin.git_files, { desc = 'Search [G]it [F]iles' })
            vim.keymap.set('n', '<leader>gs', telescope_builtin.git_status, { desc = 'Search [G]it [S]tatus' })
            vim.keymap.set('n', '<leader>gb', telescope_builtin.git_branches,
                { desc = 'Search [G]it [B]ranches' })
            vim.keymap.set('n', '<leader>sf', function()
                telescope_builtin.find_files({
                    hidden = true,
                    no_ignore = true,
                    -- no_ignore_parent = true,
                })
            end, { desc = '[S]earch [F]iles' })
            vim.keymap.set('n', '<leader>sh', telescope_builtin.help_tags, { desc = '[S]earch [H]elp' })
            vim.keymap.set('n', '<leader>sw', telescope_builtin.grep_string,
                { desc = '[S]earch current [W]ord' })
            vim.keymap.set('n', '<leader>sg', telescope_builtin.live_grep, { desc = '[S]earch by [G]rep' })
            vim.keymap.set('n', '<leader>sd', telescope_builtin.diagnostics,
                { desc = '[S]earch [D]iagnostics' })
            vim.keymap.set('n', '<leader>sr', telescope_builtin.resume, { desc = '[S]earch [R]esume' })
        end
    },
}
