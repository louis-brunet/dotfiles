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

-- local colorscheme_name = 'github_light'
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

                modules_default = false,

                modules = {
                    diagnostic = {
                        -- background = true,
                        enable = true
                    },
                    lsp_semantic_tokens = true,
                    native_lsp = {
                        background = true,
                        enable = true
                    },
                    treesitter = true

                },

                styles = {
                    -- comments = 'italic',
                },
            },

            palettes = {
                all = {
                },
                -- github_dark = {},
            },

            specs = {
                all = {
                    -- Built-in spec keys
                    git = {
                        changed = 'blue.bright',
                    },
                    syntax = {
                        string = 'green.bright',
                    },
                    -- diag = {}, diag_bg = {}, diff = {},

                    -- Custom spec keys
                    cursor_line = {
                        number_fg = 'yellow.bright',
                        number_style = 'bold',
                    },
                    fugitive = {
                        header_fg = 'gray.bright',
                        hash_fg = 'gray.bright',
                    },
                    lsp = {
                        document_highlight_read_bg = 'accent.subtle',
                        document_highlight_write_bg = 'accent.subtle',
                    },
                    nvim_tree = {
                        bg = 'none',
                        indent_marker_fg = 'neutral.muted',
                        -- modified_fg = 'gray.bright',
                    },
                    treesitter_context = {
                        -- bg = 'bg',
                        bottom_sp = 'gray',
                        bottom_style = 'underline',
                    },
                },
            },

            groups = {
                all = {
                    CursorLineNr = { style = 'cursor_line.number_style', fg = 'cursor_line.number_fg' },
                    fugitiveHash = { fg = 'fugitive.hash_fg' },
                    fugitiveHeader = { fg = 'fugitive.header_fg' },
                    fugitiveStagedHeading = { fg = 'git.add' },
                    fugitiveUnstagedHeading = { fg = 'git.changed' },
                    LspReferenceText = { bg = 'lsp.document_highlight_read_bg' },
                    LspReferenceRead = { bg = 'lsp.document_highlight_read_bg' },
                    LspReferenceWrite = { bg = 'lsp.document_highlight_write_bg', style = 'italic' },
                    LspSignatureActiveParameter = { style = 'bold,underline' },
                    NvimTreeIndentMarker = { fg = 'nvim_tree.indent_marker_fg' },
                    -- NvimTreeModifiedIcon = { fg = 'nvim_tree.modified_fg' },
                    NvimTreeEndOfBuffer = { bg = 'nvim_tree.bg' },
                    NvimTreeNormal = { bg = 'nvim_tree.bg' },
                    NvimTreeVertSplit = { bg = 'nvim_tree.bg' },
                    TabLineSel = { bg = '#31353f', fg = '#999999' },
                    TabLine = { bg = '#31353f', fg = '#555555' },
                    TelescopeNormal = { bg = 'bg2' },
                    -- TelescopePreviewNormal = { bg = 'bg1' },
                    -- TreesitterContext = { bg = 'none' },
                    -- TreesitterContextBottom = { style = 'treesitter_context.bottom_style', sp = 'treesitter_context.bottom_sp' },
                    -- DiagnosticVirtualTextError = { bg = 'palette.danger.muted', fg ='palette.danger.fg' },
                    -- DiagnosticVirtualTextWarn = { bg = 'none' },
                    -- DiagnosticVirtualTextInfo = { bg = 'none' },
                    -- DiagnosticVirtualTextHint = { bg = 'none' },
                    -- DiagnosticVirtualTextOk = { bg = 'none' },
                },
            },
        },
        config = function(_, opts)
            require('github-theme').setup(opts)
            vim.cmd.colorscheme(colorscheme_name);

            -- FIXME: wrong highlights sometimes (cursor line, column line, indent markers, ...)
            vim.api.nvim_create_user_command('TransparentToggle', function()
                local is_transparent = require('github-theme.config').options.transparent
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
                -- component_separators = '', -- '|',
                -- section_separators = '',
            },
            sections = {
                lualine_a = {
                    -- function()
                    --     -- `:h mode()`: non-zero first arg for more than 1st char
                    --     return vim.api.nvim_call_function("mode", { 1 })
                    -- end,
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
                    -- 'branch',
                },
                lualine_b = {
                    'diagnostics',
                },
                -- lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = {
                    {
                        'filename',
                        path = 3,
                    },
                    -- {
                    --     'diff',
                    --     -- colored = false,
                    -- },
                },
                lualine_x = {
                    -- codeium_status,
                    attached_lsp_clients,
                    'filetype',
                },
                lualine_y = { 'location' },
                lualine_z = {
                },
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
