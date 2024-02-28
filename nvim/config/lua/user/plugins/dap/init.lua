-- [[ Configure DAP (Debug Adapter Protocol) ]]
---@type LazySpec
local M = {
    'rcarriga/nvim-dap-ui',

    event = 'VeryLazy',

    dependencies = {
        'mfussenegger/nvim-dap',

        {
            'theHamsta/nvim-dap-virtual-text',

            dependencies = { 'nvim-treesitter/nvim-treesitter' },

            -- :h nvim-dap-virtual-text
            opts = {
                -- TODO: nvim >= 0.10, force inline virtual text
                -- virt_text_pos = 'inline'
            },
        },

        {
            'folke/neodev.nvim',
            opts = {
                library = { plugins = { 'nvim-dap-ui' }, types = true },
            },
        },

        -- DAP dependencies in lua/user/plugins/dap/*.lua (except init.lua)
        { import = 'user.plugins.dap' }
    },

    -- :h dapui.setup()
    opts = {
        -- controls = {
        --     element = "repl",
        --     enabled = true,
        --     icons = {
        --         disconnect = "",
        --         pause = "",
        --         play = "",
        --         run_last = "",
        --         step_back = "",
        --         step_into = "",
        --         step_out = "",
        --         step_over = "",
        --         terminate = ""
        --     }
        -- },
        -- element_mappings = {},
        -- expand_lines = true,
        -- floating = {
        --     border = "single",
        --     mappings = {
        --         close = { "q", "<Esc>" }
        --     }
        -- },
        -- force_buffers = true,
        -- icons = {
        --     collapsed = "",
        --     current_frame = "",
        --     expanded = ""
        -- },
        -- layouts = { {
        --     elements = { {
        --         id = "scopes",
        --         size = 0.25
        --     }, {
        --         id = "breakpoints",
        --         size = 0.25
        --     }, {
        --         id = "stacks",
        --         size = 0.25
        --     }, {
        --         id = "watches",
        --         size = 0.25
        --     } },
        --     position = "left",
        --     size = 40
        -- }, {
        --     elements = { {
        --         id = "repl",
        --         size = 0.5
        --     }, {
        --         id = "console",
        --         size = 0.5
        --     } },
        --     position = "bottom",
        --     size = 10
        -- } },
        -- mappings = {
        --     edit = "e",
        --     expand = { "<CR>", "<2-LeftMouse>" },
        --     open = "o",
        --     remove = "d",
        --     repl = "r",
        --     toggle = "t"
        -- },
        -- render = {
        --     indent = 1,
        --     max_value_lines = 100
        -- }
    }
}

return M
