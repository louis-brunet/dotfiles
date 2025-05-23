local function attached_lsp_clients_str()
    local clients = require("user.utils.lsp").get_buffer_lsp_clients()

    local names_str = ""

    for _, client in ipairs(clients) do
        if client.name ~= "" then
            names_str = names_str .. client.name .. " "
        end
    end

    return names_str
end

-- local function codeium_status()
--     return 'Codeium: ' .. vim.api.nvim_call_function("codeium#GetStatusString", {})
-- end

local colorscheme_name = require("user.config.theme").colorscheme_name

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
        -- FIXME: wrong highlights sometimes (cursor line, column line, indent markers, ...)
        --   removing ~/.cache/nvim/github-theme/github* and restarting nvim seems to fix this
        "projekt0n/github-nvim-theme",
        dependencies = {
            {
                -- Add indentation guides even on blank lines
                "lukas-reineke/indent-blankline.nvim",
                opts = {},

                -- -- See `:help indent_blankline.txt`
                -- -- event = 'VeryLazy',
                -- main = 'ibl',
                -- opts = {
                --     indent = {
                --         char = '▏',
                --         -- char = '┊',
                --     },
                --     scope = {
                --         enabled = true,
                --     },
                --     -- whitespace = {
                --     --     remove_blankline_trail = true,
                --     -- },
                -- },
                -- dependencies = {
                --     'nvim-treesitter/nvim-treesitter',
                -- },
            },
        },

        lazy = false,
        priority = 1000,
        ---@type GhTheme.Config
        opts = {
            options = {
                transparent = false,

                darken = { sidebars = { enable = false } },

                modules_default = false,

                modules = {
                    cmp = true,
                    dapui = true,
                    figet = true,
                    fzf = true,
                    gitsigns = true,
                    indent_blankline = true,
                    lsp_semantic_tokens = true,
                    lsp_trouble = true,
                    notify = true,
                    nvimtree = true,
                    telescope = true,
                    treesitter = true,
                    treesitter_context = true,
                    whichkey = true,
                    diagnostic = {
                        -- background = true,
                        enable = true,
                    },
                    native_lsp = { background = true, enable = true },
                },

                styles = { comments = "italic" },
            },

            palettes = {
                all = {},
                -- github_light = {
                -- },
            },

            -- :h github-nvim-theme-spec.syntax
            -- specs = {
            --     all = {
            --         -- Built-in spec keys
            --         git = {
            --             -- changed = 'blue.bright',
            --         },
            --         syntax = {
            --             -- ibl = {
            --             --     indent = {
            --             --         char = {
            --             --             'red',
            --             --         }
            --             --     }
            --             -- },
            --             -- string = 'green.bright',
            --         },
            --         -- diag = {}, diag_bg = {}, diff = {},
            --
            --         -- Custom spec keys
            --         color_column = {
            --             bg = 'neutral.subtle',
            --         },
            --         cursor_line = {
            --             bg = 'neutral.subtle',
            --             number_fg = 'yellow.bright',
            --             -- number_style = 'bold',
            --         },
            --         elevated = {
            --             -- bg = 'scale.gray[9]',
            --             -- bg = 'canvas.overlay',
            --             bg = 'black.bright',
            --         },
            --         -- elevated_bg = 'black',
            --         fugitive = {
            --             header_fg = 'gray.bright',
            --             hash_fg = 'gray.bright',
            --         },
            --         lsp = {
            --             inlay_hint_bg = 'none',
            --             -- FIXME: since update to v1.0, cant' reference styles or colors like this in "groups":  `{ style = 'lsp.inlay_hint_style' }`
            --             -- inlay_hint_style = 'italic',
            --             document_highlight_read_bg = 'accent.subtle',
            --             document_highlight_write_bg = 'accent.subtle',
            --         },
            --         nvim_tree = {
            --             bg = 'none',
            --             indent_marker_fg = 'neutral.muted',
            --         },
            --         treesitter_context = {
            --             bottom_sp = 'gray',
            --             bottom_style = 'underline',
            --         },
            --     },
            --     -- github_light = {
            --     -- },
            -- },
            --
            -- groups = {
            --     all = {
            --         ColorColumn = { bg = 'color_column.bg' },
            --         CursorLine = { bg = 'cursor_line.bg' },
            --         CursorLineNr = { style = 'bold', fg = 'cursor_line.number_fg' },
            --         fugitiveHash = { fg = 'fugitive.hash_fg' },
            --         fugitiveHeader = { fg = 'fugitive.header_fg' },
            --         fugitiveStagedHeading = { fg = 'git.add' },
            --         fugitiveUnstagedHeading = { fg = 'git.changed' },
            --         IblIndent = { fg = 'palette.neutral.subtle' },
            --         IblScope = { fg = 'palette.accent.muted' },
            --         LspInlayHint = { fg = 'fg3', bg = 'lsp.inlay_hint_bg', style = 'italic' },
            --         LspReferenceText = { bg = 'lsp.document_highlight_read_bg' },
            --         LspReferenceRead = { bg = 'lsp.document_highlight_read_bg' },
            --         LspReferenceWrite = { bg = 'lsp.document_highlight_write_bg', style = 'italic' },
            --         LspSignatureActiveParameter = { style = 'bold,underline' },
            --         FloatBorder = { fg = 'palette.accent.muted', bg = 'elevated.bg' },
            --         -- NormalFloat = { bg = 'elevated.bg' },
            --         NvimTreeIndentMarker = { fg = 'nvim_tree.indent_marker_fg' },
            --         -- NvimTreeModifiedIcon = { fg = 'palette.nvim_tree.modified_fg' },
            --         NvimTreeEndOfBuffer = { bg = 'nvim_tree.bg' },
            --         NvimTreeNormal = { bg = 'nvim_tree.bg' },
            --         NvimTreeVertSplit = { bg = 'nvim_tree.bg' },
            --         TabLineSel = { bg = '#31353f', fg = '#999999' },
            --         TabLine = { bg = '#31353f', fg = '#555555' },
            --         -- TelescopeNormal = { bg = 'elevated.bg' },
            --         -- WhichKeyFloat = { bg = 'elevated.bg' },
            --
            --         -- TelescopePreviewNormal = { bg = 'bg1' },
            --         -- TreesitterContext = { bg = 'none' },
            --         -- TreesitterContextBottom = { style = 'treesitter_context.bottom_style', sp = 'treesitter_context.bottom_sp' },
            --         -- DiagnosticVirtualTextError = { bg = 'palette.danger.muted', fg ='palette.danger.fg' },
            --         -- DiagnosticVirtualTextWarn = { bg = 'none' },
            --         -- DiagnosticVirtualTextInfo = { bg = 'none' },
            --         -- DiagnosticVirtualTextHint = { bg = 'none' },
            --         -- DiagnosticVirtualTextOk = { bg = 'none' },
            --     },
            --     github_light = {
            --         Delimiter = { fg = 'palette.gray' },
            --     },
            -- },

            specs = {
                all = {
                    git = {
                        -- changed = 'blue.bright',
                    },
                    -- Custom spec keys
                    -- color_column = {
                    --     bg = 'neutral.subtle',
                    -- },
                    -- color_column_bg = 'neutral',
                    -- color_column_bg = 'neutral.subtle',

                    fugitive = {
                        -- header_fg = 'gray.bright',
                        -- hash_fg = 'gray.bright',
                    },
                    lsp = {
                        inlay_hint_bg = "none",
                        -- FIXME: since update to v1.0, can't reference styles or colors like this in "groups":  `{ style = 'lsp.inlay_hint_style' }`
                        -- inlay_hint_style = 'italic',
                        --
                        -- FIXME: since update to v1.0, can't palette values in spec
                        -- document_highlight_read_bg = 'accent.subtle',
                        -- document_highlight_write_bg = 'accent.subtle',
                    },
                    nvim_tree = {
                        bg = "none",
                        -- indent_marker_fg = 'neutral.muted',
                    },
                },
            },

            groups = {
                all = {
                    fugitiveHash = { fg = "palette.gray.bright" },
                    fugitiveHeader = { fg = "palette.gray.bright" },
                    -- fugitiveHash = { fg = 'fugitive.hash_fg' },
                    -- fugitiveHeader = { fg = 'fugitive.header_fg' },
                    fugitiveStagedHeading = { fg = "git.add" },
                    fugitiveUnstagedHeading = { fg = "git.changed" },
                    IblIndent = { fg = "palette.neutral.subtle" },
                    IblScope = { fg = "palette.accent.muted" },
                    LspInlayHint = {
                        fg = "fg3",
                        bg = "lsp.inlay_hint_bg",
                        style = "italic",
                    },
                    LspReferenceText = { bg = "palette.accent.subtle" },
                    LspReferenceRead = { bg = "palette.accent.subtle" },
                    LspReferenceWrite = {
                        bg = "palette.accent.subtle",
                        style = "italic",
                    },
                    LspSignatureActiveParameter = { style = "bold,underline" },
                    NvimTreeIndentMarker = { fg = "palette.neutral.muted" },
                    -- NvimTreeIndentMarker = { fg = 'nvim_tree.indent_marker_fg' },
                    -- NvimTreeModifiedIcon = { fg = 'palette.nvim_tree.modified_fg' },
                    NvimTreeEndOfBuffer = { bg = "nvim_tree.bg" },
                    NvimTreeNormal = { bg = "nvim_tree.bg" },
                    NvimTreeVertSplit = { bg = "nvim_tree.bg" },
                    TabLineSel = { bg = "#31353f", fg = "#999999" },
                    TabLine = { bg = "#31353f", fg = "#555555" },

                    -- llama_hl_info = { link = "DiagnosticVirtualTextInfo", style = "italic" },
                    llama_hl_info = {
                        link =
                        "lualine_transitional_lualine_b_insert_to_lualine_c_insert",
                        style = "italic",
                    },
                    llama_hl_hint = { fg = "fg3", style = "" },

                    ["@module.python"] = { link = "@variable" },

                    TelescopePromptTitle = { link = "@type" },
                    TelescopePromptBorder = { link = "@type" },
                    TelescopeBorder = { fg = "palette.accent.fg" },

                    -- remove fg highlights for Diff* highlights to keep syntax
                    -- highlighting
                    DiffAdd = { style = "bold", fg = nil, bg = "#2e4b2e" },
                    DiffDelete = { style = "bold", fg = nil, bg = "#4c1e15" },
                    DiffChange = { style = "bold", fg = nil, bg = "#45565c" },
                    DiffText = { style = "bold", fg = nil, bg = "#996d74" },

                    -- Added = { link = "DiffAdd" },
                    -- Removed = { link = "DiffDelete" },
                    -- Changed = { link = "DiffChange" },
                },
            },
        },
        ---@param opts GhTheme.Config
        config = function(_, opts)
            require("github-theme").setup(opts)
            vim.cmd.colorscheme(colorscheme_name);

            local toggle_cmd_name = "TransparentToggle"

            -- toggle transparent background
            vim.api.nvim_create_user_command(toggle_cmd_name, function()
                local is_transparent = require("github-theme.config").options
                    .transparent
                opts.options.transparent = not is_transparent
                require("github-theme").setup(opts)

                vim.cmd.colorscheme(colorscheme_name)
            end, { desc = "Toggle transparent background" })

            -- vim.keymap.set({ "n", "v" }, "<leader>t",
            --     function() vim.cmd(toggle_cmd_name) end,
            --     { desc = "Toggle [T]ransparent background" }
            -- )
        end,
    },

    {
        -- Set lualine as statusline
        "nvim-lualine/lualine.nvim",
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
                lualine_b = { "diagnostics" },
                -- lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = {
                    { "filename", path = 3 },
                    -- {
                    --     'diff',
                    --     -- colored = false,
                    -- },
                },
                lualine_x = {
                    -- codeium_status,
                    attached_lsp_clients_str,
                    "filetype",
                },
                lualine_y = { "location" },
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

    -- {
    --     "echasnovski/mini.starter",
    --
    --     lazy = false,
    --
    --     -- use latest main branch
    --     version = false,
    --
    --     config = function(_, _)
    --         local starter = require("mini.starter")
    --         local sections = {
    --             common_actions = "Common actions",
    --             telescope = "Telescope",
    --         }
    --         local opts = {
    --             -- -- Whether to open starter buffer on VimEnter. Not opened if Neovim was
    --             -- -- started with intent to show something else.
    --             -- autoopen = true,
    --             --
    --             -- -- Whether to evaluate action of single active item
    --             -- evaluate_single = false,
    --
    --             -- Items to be displayed. Should be an array with the following elements:
    --             -- - Item: table with <action>, <name>, and <section> keys.
    --             -- - Function: should return one of these three categories.
    --             -- - Array: elements of these three types (i.e. item, array, function).
    --             -- If `nil` (default), default items will be used (see |mini.starter|).
    --             items = {
    --                 {
    --                     {
    --                         action = function()
    --                             require("telescope.builtin").oldfiles({
    --                                 only_cwd = true,
    --                             })
    --                         end,
    --                         name = "Recent files",
    --                         section = sections.common_actions,
    --                     },
    --                     {
    --                         action = "enew",
    --                         name = "New file",
    --                         section = sections.common_actions,
    --                     },
    --                     {
    --                         action = "Git",
    --                         name = "Git status",
    --                         section = sections.common_actions,
    --                     },
    --                     {
    --                         action = "NvimTreeToggle",
    --                         name = "Open file tree",
    --                         section = sections.common_actions,
    --                     },
    --                 },
    --                 -- starter.sections.builtin_actions(),
    --                 -- { { action = "Git", name = "Git status", section = "Git" }, },
    --                 starter.sections.recent_files(5, true, true),
    --                 -- {
    --                 --     {
    --                 --         action = "Telescope find_files",
    --                 --         name = "Files",
    --                 --         section = sections.telescope,
    --                 --     },
    --                 --     {
    --                 --         action = "Telescope oldfiles",
    --                 --         name = "Recent files",
    --                 --         section = sections.telescope,
    --                 --     },
    --                 --     {
    --                 --         action = function()
    --                 --             require("user.utils.telescope").multigrep({})
    --                 --         end,
    --                 --         name = "Grep",
    --                 --         section = sections.telescope,
    --                 --     },
    --                 --     {
    --                 --         action = "Telescope command_history",
    --                 --         name = "Command history",
    --                 --         section = sections.telescope,
    --                 --     },
    --                 --     {
    --                 --         action = "Telescope help_tags",
    --                 --         name = "Help tags",
    --                 --         section = sections.telescope,
    --                 --     },
    --                 -- },
    --             },
    --
    --             -- Header to be displayed before items. Converted to single string via
    --             -- `tostring` (use `\n` to display several lines). If function, it is
    --             -- evaluated first. If `nil` (default), polite greeting will be used.
    --             header = function()
    --                 return table.concat({
    --                     -- [[  ___     ___    ___   __  __ /\_\    ___ ___    ]],
    --                     -- [[ / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
    --                     -- [[/\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
    --                     -- [[\ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
    --                     -- [[ \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
    --                     -- [[                                                 ]],
    --
    --                     -- [[  ██████   █████                   █████   █████  ███                  ]],
    --                     -- [[ ░░██████ ░░███                   ░░███   ░░███  ░░░                   ]],
    --                     -- [[  ░███░███ ░███   ██████   ██████  ░███    ░███  ████  █████████████   ]],
    --                     -- [[  ░███░░███░███  ███░░███ ███░░███ ░███    ░███ ░░███ ░░███░░███░░███  ]],
    --                     -- [[  ░███ ░░██████ ░███████ ░███ ░███ ░░███   ███   ░███  ░███ ░███ ░███  ]],
    --                     -- [[  ░███  ░░█████ ░███░░░  ░███ ░███  ░░░█████░    ░███  ░███ ░███ ░███  ]],
    --                     -- [[  █████  ░░█████░░██████ ░░██████     ░░███      █████ █████░███ █████ ]],
    --                     -- [[ ░░░░░    ░░░░░  ░░░░░░   ░░░░░░       ░░░      ░░░░░ ░░░░░ ░░░ ░░░░░  ]],
    --                     -- [[                                                                       ]],
    --
    --                     -- [[  ___    __    _   _   _(_) ___ ___  ]],
    --                     -- [[/  _  \/ __ \/ _ \( ) ( ) |  _   _  \]],
    --                     -- [[| ( ) |  ___/ (_) ) \_/ | | ( ) ( ) |]],
    --                     -- [[(_) (_)\____)\___/ \___/(_)_) (_) (_)]],
    --                     -- [[                                     ]],
    --
    --
    --                     -- [[ _  _  _    .__ ]],
    --                     -- [[| |(/_(_)\/ ||||]],
    --                     -- [[                ]],
    --
    --                     [[                 _       ]],
    --                     [[ ___ ___ ___ _ _|_|_____ ]],
    --                     [[|   | -_| . | | | |     |]],
    --                     [[|_|_|___|___|\_/|_|_|_|_|]],
    --                     [[                         ]],
    --
    --                     -- [[    ++         +    ]],
    --                     -- [[   ++++        ++   ]],
    --                     -- [[. \+++++       ++++ ]],
    --                     -- [[+\ \+++++      +++++]],
    --                     -- [[++\ \+++++     +++++]],
    --                     -- [[+++\ ++++++    ++++]],
    --                     -- [[+++++  ++++++  +++++]],
    --                     -- [[+++++   ++++++ +++++]],
    --                     -- [[+++++    ++++++ \+++]],
    --                     -- [[+++++      +++++. ++]],
    --                     -- [[ ++++       ++++++  ]],
    --                     -- [[   ++        +++++  ]],
    --                     -- [[    +         ++    ]],
    --
    --
    --                     -- os.date("%Y-%m-%d"),
    --                 }, "\n")
    --             end,
    --
    --             -- Footer to be displayed after items. Converted to single string via
    --             -- `tostring` (use `\n` to display several lines). If function, it is
    --             -- evaluated first. If `nil` (default), default usage help will be shown.
    --             footer = function()
    --                 return table.concat({
    --                     os.date("%Y-%m-%d"),
    --                     "Neovim " .. tostring(vim.version()),
    --                 }, "\n")
    --             end,
    --
    --             -- -- Array  of functions to be applied consecutively to initial content.
    --             -- -- Each function should take and return content for 'Starter' buffer (see
    --             -- -- |mini.starter| and |MiniStarter.content| for more details).
    --             -- content_hooks = nil,
    --             --
    --             -- -- Characters to update query. Each character will have special buffer
    --             -- -- mapping overriding your global ones. Be careful to not add `:` as it
    --             -- -- allows you to go into command mode.
    --             -- query_updaters = "abcdefghijklmnopqrstuvwxyz0123456789_-.",
    --             --
    --             -- -- Whether to disable showing non-error feedback
    --             -- silent = false,
    --         }
    --         starter.setup(opts)
    --     end,
    -- },
}
