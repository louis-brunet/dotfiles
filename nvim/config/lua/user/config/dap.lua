local M = {}


local function config_javascript()
    local dap = require('dap')

    if not dap.adapters['pwa-node'] then
        dap.adapters['pwa-node'] = {
            type = 'server',
            host = 'localhost',
            port = '${port}',
            executable = {
                command = 'node',
                -- 💀 Make sure to update this path to point to your installation
                args = {
                    require('mason-registry').get_package('js-debug-adapter'):get_install_path()
                    .. '/js-debug/src/dapDebugServer.js',
                    '${port}',
                },
            },
        }
    end

    for _, language in ipairs({ 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' }) do
        if not dap.configurations[language] then
            dap.configurations[language] = {
                {
                    type = 'pwa-node',
                    request = 'launch',
                    name = 'Launch file',
                    program = '${file}',
                    cwd = '${workspaceFolder}',
                    console = 'integratedTerminal',
                },
                {
                    type = 'pwa-node',
                    request = 'attach',
                    name = 'Attach',
                    processId = require('dap.utils').pick_process,
                    cwd = '${workspaceFolder}',
                    console = 'integratedTerminal',
                },
            }
        end
    end
end


local icons = {
    Stopped             = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
    Breakpoint          = " ",
    BreakpointCondition = " ",
    BreakpointRejected  = { " ", "DiagnosticError" },
    LogPoint            = ".>",
}


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


-- config() for nvim-dap
M.config_dap = function()
    vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

    for name, sign in pairs(icons) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
            "Dap" .. name,
            { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
    end


    vim.api.nvim_create_user_command('DapBreakpointsList', function()
        require('dap').list_breakpoints(true);
    end, { desc = 'Dap: List breakpoints (quickfix)' })

    vim.api.nvim_create_user_command('DapBreakpointsClear', function()
        require('dap').clear_breakpoints();
    end, { desc = 'Dap: Clear breakpoints' })

    config_javascript();
end

-- keymaps used to lazy-load nvim-dap
M.dap_keys = {
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "DAP: [B]reakpoint Condition" },
    { "<leader>db", function() require("dap").toggle_breakpoint() end,                                    desc = "DAP: Toggle [b]reakpoint" },
    { "<leader>dc", function() require("dap").continue() end,                                             desc = "DAP: [c]ontinue" },
    { "<leader>da", function() require("dap").continue({ before = get_args }) end,                        desc = "DAP: Run with [a]rgs" },
    { "<leader>dC", function() require("dap").run_to_cursor() end,                                        desc = "DAP: Run to [C]ursor" },
    { "<leader>dg", function() require("dap").goto_() end,                                                desc = "DAP: [g]o to line (no execute)" },
    { "<leader>di", function() require("dap").step_into() end,                                            desc = "DAP: Step [I]nto" },
    { "<leader>dj", function() require("dap").down() end,                                                 desc = "DAP: Down" },
    { "<leader>dk", function() require("dap").up() end,                                                   desc = "DAP: Up" },
    { "<leader>dl", function() require("dap").run_last() end,                                             desc = "DAP: Run [g]ast" },
    { "<leader>do", function() require("dap").step_out() end,                                             desc = "DAP: Step [o]ut" },
    { "<leader>dO", function() require("dap").step_over() end,                                            desc = "DAP: Step [O]ver" },
    { "<leader>dp", function() require("dap").pause() end,                                                desc = "DAP: [p]ause" },
    { "<leader>dr", function() require("dap").repl.toggle() end,                                          desc = "DAP: Toggle [r]EPL" },
    { "<leader>dS", function() require("dap").session() end,                                              desc = "DAP: [S]ession" },
    { "<leader>dt", function() require("dap").terminate() end,                                            desc = "DAP: [t]erminate" },
    { "<leader>dw", function() require("dap.ui.widgets").hover() end,                                     desc = "DAP: [w]idgets" },
}

M.dapui_keys = {
    { "<leader>du", function() require("dapui").toggle({}) end, desc = "DAP: Toggle [U]I" },
    { "<leader>de", function() require("dapui").eval() end,     desc = "DAP: [E]val",     mode = { "n", "v" } },
}

-- :h mason-nvim-dap.nvim-available-dap-adapters
-- https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua
M.mason_nvim_dap_ensure_installed = {
    'js',
}

return M
