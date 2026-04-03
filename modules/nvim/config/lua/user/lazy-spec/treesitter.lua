---@type TSConfig
---@diagnostic disable-next-line: missing-fields
local treesitter_opts = {
    -- Add languages to be installed here that you want installed for treesitter
    ensure_installed = {
        'c', 'go', 'html', 'http', 'json', 'lua', 'python', 'rust',
        'tsx', 'javascript', 'typescript', 'vimdoc', 'vim',
        'latex',
    },

    -- Autoinstall languages that are not installed. Defaults to false
    auto_install = true,

    highlight = {
        enable = true,
        -- disable highlighting in case of treesitter errors
        disable = {
            -- 'html',
        },
    },

    indent = { enable = true },

    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = '<c-space>',
            node_incremental = '<c-space>',
            scope_incremental = '<c-s>',
            node_decremental = '<M-space>',
        },
    },

    textobjects = {
        -- lsp_interop = {
        --     enable = true,
        --     peek_definition_code = {
        --         ['<leader>df'] = '@function.outer',
        --         ['<leader>dF'] = '@class.outer',
        --     },
        -- },
        select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
            keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ['aa'] = '@parameter.outer',
                ['ia'] = '@parameter.inner',
                ['af'] = '@function.outer',
                ['if'] = '@function.inner',
                ['ac'] = '@class.outer',
                ['ic'] = '@class.inner',
            },
            selection_modes = { -- '<c-v>' for blockwise
                ['@parameter.outer'] = 'v', -- charwise
                ['@function.outer'] = 'V', -- linewise
                ['@class.outer'] = 'V',
            },
        },
        move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
                [']m'] = '@function.outer',
                [']]'] = '@class.outer',
                [']a'] = '@parameter.outer',
            },
            goto_next_end = {
                [']M'] = '@function.outer',
                [']['] = '@class.outer',
                [']A'] = '@parameter.outer',
            },
            goto_previous_start = {
                ['[m'] = '@function.outer',
                ['[['] = '@class.outer',
                ['[a'] = '@parameter.outer',
            },
            goto_previous_end = {
                ['[M'] = '@function.outer',
                ['[]'] = '@class.outer',
                ['[A'] = '@parameter.outer',
            },
        },
        swap = {
            enable = true,
            swap_next = {
                ['<leader>a'] = '@parameter.inner',
            },
            swap_previous = {
                ['<leader>A'] = '@parameter.inner',
            },
        },
    },
}

---@type LazySpec
return {
    {
        -- Highlight, edit, and navigate code
        'nvim-treesitter/nvim-treesitter',
        branch = "main",
        lazy = false,
        dependencies = {
            -- manipulate treesitter objects (parameter names, functions, properties, etc.)
            {
              "nvim-treesitter/nvim-treesitter-textobjects",
              branch = "main",
              init = function()
                -- Disable entire built-in ftplugin mappings to avoid conflicts.
                -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
                vim.g.no_plugin_maps = true

                -- Or, disable per filetype (add as you like)
                -- vim.g.no_python_maps = true
                -- vim.g.no_ruby_maps = true
                -- vim.g.no_rust_maps = true
                -- vim.g.no_go_maps = true
              end,
              config = function()
                -- put your config here
              end,
            },
            -- keep context of cursor position (e.g. fn name) sticky at the top
            'nvim-treesitter/nvim-treesitter-context',
        },
        build = ':TSUpdate',
        opts = treesitter_opts,
        config = function (_, opts)
            require("nvim-treesitter").setup(opts)

            vim.treesitter.language.register('html', 'ejs')
            vim.treesitter.language.register('html', 'handlebars')

            vim.treesitter.language.register('angular', 'angular.html')
        end
    },
}
