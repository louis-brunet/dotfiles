-- [[ Configure DAP (Debug Adapter Protocol) ]]


---@param config {args?:string[]|fun():string[]?}
local function get_args(config)
    local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
    config = vim.deepcopy(config)
    ---@cast args string[]
    config.args = function()
        local new_args = vim.fn.input("Run with args: ", table.concat(args, " ")) --[[@as string]]
        return vim.split(vim.fn.expand(new_args) --[[@as string]], " ")
    end
    return config
end


---@type LazySpec
local M = {
    'mfussenegger/nvim-dap',

    -- event = 'VeryLazy',

    dependencies = {
        -- fancy UI for the debugger
        {
            'rcarriga/nvim-dap-ui',

            keys = {
                { "<leader>du", function() require("dapui").toggle({}) end, desc = "Dap UI" },
                { "<leader>de", function() require("dapui").eval() end,     desc = "Dap Eval", mode = { "n", "v" } },
            },

            dependencies = {
                {
                    'folke/neodev.nvim',
                    opts = {
                        library = { plugins = { 'nvim-dap-ui' }, types = true },
                    },
                },
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

        -- mason.nvim integration
        {
            "jay-babu/mason-nvim-dap.nvim",
            dependencies = "mason.nvim",
            -- cmd = { "DapInstall", "DapUninstall" },
            opts = {
                -- Makes a best effort to setup the various debuggers with
                -- reasonable debug configurations
                automatic_installation = true,

                -- You can provide additional configuration to the handlers,
                -- see mason-nvim-dap README for more information
                handlers = {},

                -- You'll need to check that you have the required things installed
                -- online
                ensure_installed = {
                    'js',
                },
            },
        },

        -- DAP dependencies in lua/user/plugins/dap/*.lua (except init.lua)
        -- { import = 'user.plugins.dap' },
    },

    keys = {
        { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
        { "<leader>db", function() require("dap").toggle_breakpoint() end,                                    desc = "Toggle Breakpoint" },
        { "<leader>dc", function() require("dap").continue() end,                                             desc = "Continue" },
        { "<leader>da", function() require("dap").continue({ before = get_args }) end,                        desc = "Run with Args" },
        { "<leader>dC", function() require("dap").run_to_cursor() end,                                        desc = "Run to Cursor" },
        { "<leader>dg", function() require("dap").goto_() end,                                                desc = "Go to line (no execute)" },
        { "<leader>di", function() require("dap").step_into() end,                                            desc = "Step Into" },
        { "<leader>dj", function() require("dap").down() end,                                                 desc = "Down" },
        { "<leader>dk", function() require("dap").up() end,                                                   desc = "Up" },
        { "<leader>dl", function() require("dap").run_last() end,                                             desc = "Run Last" },
        { "<leader>do", function() require("dap").step_out() end,                                             desc = "Step Out" },
        { "<leader>dO", function() require("dap").step_over() end,                                            desc = "Step Over" },
        { "<leader>dp", function() require("dap").pause() end,                                                desc = "Pause" },
        { "<leader>dr", function() require("dap").repl.toggle() end,                                          desc = "Toggle REPL" },
        { "<leader>dS", function() require("dap").session() end,                                              desc = "Session" },
        { "<leader>dt", function() require("dap").terminate() end,                                            desc = "Terminate" },
        { "<leader>dw", function() require("dap.ui.widgets").hover() end,                                     desc = "Widgets" },
    },

    config = require('user.config.dap').config_dap,
    -- function()
        -- local icons = {
        --     Stopped             = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
        --     Breakpoint          = " ",
        --     BreakpointCondition = " ",
        --     BreakpointRejected  = { " ", "DiagnosticError" },
        --     LogPoint            = ".>",
        -- }
        -- vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
        --
        -- for name, sign in pairs(icons) do
        --     sign = type(sign) == "table" and sign or { sign }
        --     vim.fn.sign_define(
        --         "Dap" .. name,
        --         { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        --     )
        -- end
    -- end,
}

return M
