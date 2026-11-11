---@type table<string, string|[string, string, string]>
local icons = {
    Stopped             = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
    Breakpoint          = " ",
    BreakpointCondition = " ",
    BreakpointRejected  = { " ", "DiagnosticError" },
    LogPoint            = ".>",
}

---@class UserDapConfigLanguageModule
---@field configure fun(): nil

---@class UserDapCommand
---@field name string
---@field cmd fun(): nil
---@field desc string

---@type UserDapCommand[]
local user_cmds = {
    {
        name = "DapBreakpointsList",
        cmd = function() require("dap").list_breakpoints(true) end,
        desc = "List breakpoints (quickfix)",
    },
    {
        name = "DapBreakpointsTelescope",
        cmd = function()
            require("dap").list_breakpoints(false)
            require("telescope.builtin").quickfix()
        end,
        desc = "List breakpoints (Telescope)",
    },
    {
        name = "DapBreakpointsClear",
        cmd = function() require("dap").clear_breakpoints(); end,
        desc = "Clear breakpoints",
    },
}

---@param config {args?:string[]|fun():string[]?}
local function get_args(config)
    local args = type(config.args) == "function" and (config.args() or {}) or
        config.args or {}
    config = vim.deepcopy(config)

    ---@cast args string[]
    config.args = function()
        local new_args = vim.fn.input("Run with args: ", table.concat(args, " "))  --[[@as string]]
        return vim.split(vim.fn.expand(new_args)  --[[@as string]], " ")
    end
    return config
end




---@class UserDapConfig
local M = {}

--- Commands used to lazy-load nvim-dap
---@type string[]
M.dap_cmd = { "DapToggleBreakpoint", "DapContinue", "DapShowLog" }
for _, user_cmd in ipairs(user_cmds) do
    table.insert(M.dap_cmd, user_cmd.name)
end

-- config() for nvim-dap
function M.dap_config()
    vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

    for name, sign in pairs(icons) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
            "Dap" .. name,
            {
                text = sign[1],
                texthl = sign[2] or "DiagnosticInfo",
                linehl = sign[3],
                numhl = sign[3],
            }
        )
    end

    for _, user_cmd in ipairs(user_cmds) do
        vim.api.nvim_create_user_command(user_cmd.name, user_cmd.cmd,
            { desc = "DAP: " .. user_cmd.desc })
    end

    require("user.config.dap.js").configure()
    require("user.config.dap.rust").configure()
end

-- require("lazy")

--- keymaps used to lazy-load nvim-dap
---@type LazyKeysSpec[]
M.dap_keys = {
    {
        "<leader>dB",
        function()
            require("dap").set_breakpoint(vim.fn.input(
                "Breakpoint condition: "))
        end,
        desc = "DAP: [B]reakpoint Condition",
    },
    {
        "<leader>db",
        function() require("dap").toggle_breakpoint() end,
        desc = "DAP: Toggle [b]reakpoint",
    },
    {
        "<leader>dc",
        function() require("dap").continue() end,
        desc = "DAP: [c]ontinue",
    },
    {
        "<leader>da",
        function() require("dap").continue({ before = get_args }) end,
        desc = "DAP: Run with [a]rgs",
    },
    {
        "<leader>dC",
        function() require("dap").run_to_cursor() end,
        desc = "DAP: Run to [C]ursor",
    },
    {
        "<leader>dg",
        function() require("dap").goto_() end,
        desc = "DAP: [g]o to line (no execute)",
    },
    {
        "<leader>di",
        function() require("dap").step_into() end,
        desc = "DAP: Step [I]nto",
    },
    { "<leader>dj", function() require("dap").down() end, desc = "DAP: Down" },
    { "<leader>dk", function() require("dap").up() end,   desc = "DAP: Up" },
    {
        "<leader>dl",
        function() require("dap").run_last() end,
        desc = "DAP: Run [l]ast",
    },
    {
        "<leader>do",
        function() require("dap").step_out() end,
        desc = "DAP: Step [o]ut",
    },
    {
        "<leader>dO",
        function() require("dap").step_over() end,
        desc = "DAP: Step [O]ver",
    },
    { "<leader>dp", function() require("dap").pause() end,   desc = "DAP: [p]ause" },
    {
        "<leader>dr",
        function() require("dap").repl.toggle() end,
        desc = "DAP: Toggle [r]EPL",
    },
    { "<leader>dS", function() require("dap").session() end, desc = "DAP: [S]ession" },
    {
        "<leader>dt",
        function() require("dap").terminate() end,
        desc = "DAP: [t]erminate",
    },
    {
        "<leader>dw",
        function() require("dap.ui.widgets").hover() end,
        desc = "DAP: [w]idgets",
    },
}

---@type LazyKeysSpec[]
M.dapui_keys = {
    {
        "<leader>du",
        function() require("dapui").toggle({}) end,
        desc = "DAP: Toggle [u]i",
    },
    {
        "<leader>dU",
        function() require("dapui").open({ reset = true }) end,
        desc = "DAP: Reset [U]I",
    },
    {
        "<leader>de",
        function() require("dapui").eval() end,
        desc = "DAP: [e]val",
        mode = { "n", "v" },
    },
}

--- :h mason-nvim-dap.nvim-available-dap-adapters
--- https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua
---@type string[]
M.mason_nvim_dap_ensure_installed = {
    "js",
    -- 'codelldb',
    -- 'python',
}

return M
