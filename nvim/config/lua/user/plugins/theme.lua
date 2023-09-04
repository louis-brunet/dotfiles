---@type LazySpec
return {
    {
        -- Theme inspired by Atom
        'navarasu/onedark.nvim',
        priority = 1000,
        opts = {
            transparent = true,
            lualine = {
                transparent = true,
            },
            highlights = {
                TreesitterContextBottom = { fmt = "underline", sp = "Grey" },
                TreesitterContext = { bg = "none" },
                NvimTreeIndentMarker = { fg = "#31353f" },
                NvimTreeNormal = { bg = "none" },
                NvimTreeEndOfBuffer = { bg = "none" },
                NvimTreeVertSplit = { bg = "none" },
                TabLineSel = { bg = "#31353f", fg = "#999999" },
                TabLine = { bg = "#31353f", fg = "#555555" },
                CursorLineNr = { fmt = "bold", fg = "#ccbb44" },
                DiagnosticVirtualTextError = { bg = "none" },
                DiagnosticVirtualTextWarn = { bg = "none" },
                DiagnosticVirtualTextInfo = { bg = "none" },
                DiagnosticVirtualTextHint = { bg = "none" },
                DiagnosticVirtualTextOk = { bg = "none" },
                LspSignatureActiveParameter = { fmt = "bold,underline" },
            },
        },
        config = function(_, opts)
            require('onedark').setup(opts)
            vim.cmd.colorscheme 'onedark'

            vim.api.nvim_create_user_command('TransparentToggle', function()
                local onedark = require 'onedark'
                onedark.setup {
                    transparent = not vim.g.onedark_config.transparent,
                }
                vim.cmd.colorscheme 'onedark'
                -- onedark.load()
            end, { desc = "Toggle transparent background" })
        end,
    },

    {
        -- Set lualine as statusline
        'nvim-lualine/lualine.nvim',
        -- See `:help lualine.txt`
        opts = {
            options = {
                -- icons_enabled = false,
                theme = 'onedark',
                -- component_separators = '|',
                -- section_separators = '',
            },
            sections = {
                lualine_a = {
                    {
                        'mode',
                        fmt = function(str)
                            if str:sub(1, 2) == 'V-' then
                                return str:lower()
                            end

                            return str:sub(1, 1):lower()
                        end,
                    },
                },
                -- lualine_b = { 'branch', 'diff' },
                lualine_c = {
                    -- 'diagnostics',
                    {
                        'filename',
                        path = 3,
                    },
                },
                lualine_x = { 'filetype' },
                lualine_y = { 'location' },
                lualine_z = {},
            },
            tabline = {
                -- lualine_a = { 'tabs' },
            },
        },
    },

    {
        'alvarosevilla95/luatab.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        config = function()
            -- highlight groups are defined in onedark config
            require('luatab').setup {
                separator = function() -- (index)
                    -- return ''
                    return ''
                end
            }
        end
    },
}
