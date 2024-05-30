---@type LazySpec
return {
    -- fancy UI for the debugger
    {
        'rcarriga/nvim-dap-ui',

        keys = require('user.config.dap').dapui_keys,

        dependencies = {
            {
                'folke/neodev.nvim',
                opts = {
                    library = { plugins = { 'nvim-dap-ui' }, types = true },
                },
            },
            'nvim-neotest/nvim-nio'
        },

        -- :h dapui.setup()
        -- opts = {}

        config = function(_, opts)
            -- setup dap config by VsCode launch.json file
            -- require("dap.ext.vscode").load_launchjs()

            local dap = require("dap")
            local dapui = require("dapui")
            dapui.setup(opts)
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open({})
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close({})
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close({})
            end
        end,
    },

    -- virtual text for the debugger
    {
        'theHamsta/nvim-dap-virtual-text',

        dependencies = { 'nvim-treesitter/nvim-treesitter' },

        -- :h nvim-dap-virtual-text
        opts = {
            -- TODO: nvim >= 0.10, force inline virtual text
            -- virt_text_pos = 'inline'
        },
    },

}
