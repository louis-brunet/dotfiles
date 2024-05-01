-- It is strongly advised to eagerly disable netrw, due to race conditions at
-- vim startup.
-- Set the following at the very beginning of your `init.lua` / `init.vim`:
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

---@type LazySpec
return {
    {
        'nvim-tree/nvim-tree.lua',

        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },

        opts = {
            --- Keeps the cursor on the first letter of the filename when moving in the tree.
            -- hijack_cursor = true,

            select_prompts = true,

            -- diagnostics = {
            --     enable = true
            -- },

            filters = {
                git_ignored = false,
            },

            -- tab = {
            --     sync = {
            --         open = true,
            --         close = true,
            --     },
            -- },

            modified = {
                enable = true,
            },

            view = {
                -- side = 'right',
                width = {
                    min = 20,
                    max = 50,    -- -1 for unbounded
                    padding = 1, -- to the right
                },
                -- float = {
                --     enable = true,
                -- },
            },

            renderer = {
                add_trailing = true,

                group_empty = true,

                -- use floating window if long file name overflows
                -- NOTE: does not work when view.side is 'right'
                full_name = true,

                special_files = {
                    'package.json',

                    -- defaults
                    'Cargo.toml', 'Makefile', 'README.md', 'readme.md',
                },

                indent_markers = {
                    enable = true,
                },

                icons = {
                    show = {
                        folder_arrow = false,
                    },
                    glyphs = {
                        modified = '+',
                        -- folder = {
                        --     -- arrow_closed = '▶',
                        --     -- arrow_open = '▼',
                        -- },
                    },
                },
            },
        },

        -- highlights are defined in the colorscheme config (./theme.lua)
        config = function(_, opts)
            require('nvim-tree').setup(opts)

            vim.keymap.set('n', '<C-n>', ':NvimTreeFindFileToggle<CR>', {
                silent = true,
                desc = 'nvim-tree: toggle sidebar',
            });
        end,
    },
}
