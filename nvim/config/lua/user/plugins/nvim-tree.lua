return {
    {
        'nvim-tree/nvim-tree.lua',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        -- highlights are defined in the onedark config
        config = function()
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
            require('nvim-tree').setup({
                filters = {
                    git_ignored = false,
                },
                tab = {
                    sync = {
                        open = true,
                        close = true,
                    },
                },
                renderer = {
                    group_empty = true,
                    add_trailing = true,
                    indent_markers = {
                        enable = true,
                    },
                    icons = {
                        show = {
                            folder_arrow = false,
                        },
                        glyphs = {
                            -- folder = {
                            --     -- arrow_closed = '▶',
                            --     -- arrow_open = '▼',
                            -- },
                        },
                    },
                },
            })
            vim.keymap.set('n', '<C-n>', ':NvimTreeFindFileToggle<CR>');
        end,
    },
}
