local function attached_lsp_clients()
    local names_str = ''
    for _, client in ipairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
        if client.name ~= '' then
            if names_str == '' then
                names_str = client.name
            else
                names_str = names_str .. ' ' .. client.name
            end
        end
    end
    return names_str
end

local function codeium_status()
    return 'Codeium: ' .. vim.api.nvim_call_function("codeium#GetStatusString", {})
end

local colorscheme_name = 'github_dark_dimmed'

---@type LazySpec
return {
    -- {
    --     -- Theme inspired by Atom
    --     'navarasu/onedark.nvim',
    --     lazy = false,
    --     priority = 1000,
    --     opts = {
    --         transparent = true,
    --         lualine = {
    --             transparent = true,
    --         },
    --         style = 'warm',
    --         highlights = {
    --             -- Normal = { bg = "#2e3436" }, -- change default background from #282c34
    --             TreesitterContextBottom = { fmt = "underline", sp = "Grey" },
    --             TreesitterContext = { bg = "none" },
    --             NvimTreeIndentMarker = { fg = "#31353f" },
    --             NvimTreeNormal = { bg = "none" },
    --             NvimTreeEndOfBuffer = { bg = "none" },
    --             NvimTreeVertSplit = { bg = "none" },
    --             TabLineSel = { bg = "#31353f", fg = "#999999" },
    --             TabLine = { bg = "#31353f", fg = "#555555" },
    --             CursorLineNr = { fmt = "bold", fg = "#ccbb44" },
    --             DiagnosticVirtualTextError = { bg = "none" },
    --             DiagnosticVirtualTextWarn = { bg = "none" },
    --             DiagnosticVirtualTextInfo = { bg = "none" },
    --             DiagnosticVirtualTextHint = { bg = "none" },
    --             DiagnosticVirtualTextOk = { bg = "none" },
    --             LspSignatureActiveParameter = { fmt = "bold,underline" },
    --         },
    --     },
    --     config = function(_, opts)
    --         require('onedark').setup(opts)
    --         vim.cmd.colorscheme(colorscheme_name)
    --
    --         vim.api.nvim_create_user_command('TransparentToggle', function()
    --             local onedark = require 'onedark'
    --             onedark.setup {
    --                 transparent = not vim.g.onedark_config.transparent,
    --             }
    --             vim.cmd.colorscheme(colorscheme_name)
    --         end, { desc = "Toggle transparent background" })
    --     end,
    -- },
    {
        'projekt0n/github-nvim-theme',
        lazy = false,
        priority = 1000,
        opts = {
            options = {
                transparent = false,
                darken = {
                    sidebars = {
                        enabled = false,
                    },
                },
            },
            palettes = {
                all = {
                },
                -- github_dark = {},
            },
            specs = {
                all = {
                    git = {
                        changed = 'cyan',
                    },

                    treesitter_context = {
                        bg = 'black',
                        bottom_sp = 'black.bright',
                        bottom_style = 'underline',
                    },
                    nvim_tree = {
                        bg = 'none',
                        indent_marker_fg = '#31353f',
                    },
                    cursor_line = {
                        number_fg = '#ccbb44',
                        number_style = 'bold',
                    },
                },
            },
            groups = {
                all = {
                    TreesitterContextBottom = { style = 'treesitter_context.bottom_style', sp = 'treesitter_context.bottom_sp' },
                    TreesitterContext = { bg = 'treesitter_context.bg' },
                    NvimTreeIndentMarker = { fg = 'nvim_tree.indent_marker_fg' },
                    NvimTreeNormal = { bg = 'nvim_tree.bg' },
                    NvimTreeEndOfBuffer = { bg = 'nvim_tree.bg' },
                    NvimTreeVertSplit = { bg = 'nvim_tree.bg' },
                    TabLineSel = { bg = '#31353f', fg = '#999999' },
                    TabLine = { bg = '#31353f', fg = '#555555' },
                    CursorLineNr = { style = 'cursor_line.number_style', fg = 'cursor_line.number_fg' },
                    -- DiagnosticVirtualTextError = { bg = 'none' },
                    -- DiagnosticVirtualTextWarn = { bg = 'none' },
                    -- DiagnosticVirtualTextInfo = { bg = 'none' },
                    -- DiagnosticVirtualTextHint = { bg = 'none' },
                    -- DiagnosticVirtualTextOk = { bg = 'none' },
                    LspSignatureActiveParameter = { style = 'bold,underline' },
                },
            },
        },
        config = function(_, opts)
            require('github-theme').setup(opts)
            vim.cmd.colorscheme(colorscheme_name);

            vim.api.nvim_create_user_command('TransparentToggle', function()
                local is_transparent = require('github-theme.config').options.transparent
                -- require('github-theme').setup({
                require('github-theme').setup({
                    options = {
                        transparent = not is_transparent,
                    },
                })

                vim.cmd.colorscheme(colorscheme_name)
            end, { desc = "Toggle transparent background" })
        end
    },

    {
        -- Set lualine as statusline
        'nvim-lualine/lualine.nvim',
        -- See `:help lualine.txt`
        opts = {
            options = {
                -- icons_enabled = false,
                theme = colorscheme_name,
                component_separators = '', -- '|',
                section_separators = '',
            },
            sections = {
                lualine_a = {
                    function()
                        -- `:h mode()`: non-zero first arg for more than 1st char
                        return vim.api.nvim_call_function("mode", { 1 })
                    end,
                    -- {
                    --     'mode',
                    --     fmt = function(str)
                    --         if str:sub(1, 2) == 'V-' then
                    --             return str:lower()
                    --         end
                    --
                    --         return str:sub(1, 1):lower()
                    --     end,
                    -- },
                },
                lualine_b = { 'diagnostics' },
                -- lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = {
                    {
                        'filename',
                        path = 3,
                    },
                },
                lualine_x = { --[[codeium_status,--]] attached_lsp_clients, 'filetype' },
                lualine_y = { 'location' },
                lualine_z = {},
            },
            tabline = {
                -- lualine_a = { 'tabs' },
            },
        },
    },

    -- {
    --     'alvarosevilla95/luatab.nvim',
    --     dependencies = {
    --         'nvim-tree/nvim-web-devicons',
    --     },
    --     config = function()
    --         -- highlight groups are defined in onedark config
    --         require('luatab').setup {
    --             separator = function() -- (index)
    --                 -- return ''
    --                 return ''
    --             end
    --         }
    --     end
    -- },
}
