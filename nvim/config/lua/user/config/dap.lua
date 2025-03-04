---@param language string
---@param dap_configs dap.Configuration[]
local function set_configs_if_not_defined(language, dap_configs)
    local dap = require("dap")

    if not dap.configurations[language] then
        dap.configurations[language] = dap_configs
    end
end


---@param adapter_key string
---@param dap_adapter dap.Adapter|fun(callback: fun(adapter:dap.Adapter), config: dap.Configuration)
local function set_adapter_if_not_defined(adapter_key, dap_adapter)
    local dap = require("dap")

    if not dap.adapters[adapter_key] then
        dap.adapters[adapter_key] = dap_adapter
    end
end


local function config_rust()
    -- vim.ui.input(input_opts, input_on_confirm)
    local adapter_key = "rust_codelldb";
    set_adapter_if_not_defined(adapter_key, {
        type = "server",
        port = "${port}",
        host = "127.0.0.1",
        executable = {
            -- command = 'codelldb',
            -- TODO: 💀 Make sure to update this path to point to your installation
            command = require("mason-registry").get_package("codelldb")
                :get_install_path()
                .. "/codelldb",
            args = {
                -- '--liblldb', liblldb_path,
                "--port",
                "${port}",
            },
        },
    })

    set_configs_if_not_defined("rust", {
        -- {
        --     type = adapter_key,
        --     request = 'launch',
        --     name = 'TODO: this config (Launch file or smth)',
        --     -- program = '${file}',
        --     cwd = '${workspaceFolder}',
        --     -- args = opts.executable_args or {},
        --     -- console = 'integratedTerminal',
        -- },

        {
            name = "TODO: config?",
            type = adapter_key,
            request = "launch",
            cargo = {
                args = { "test", "--no-run", "--lib", "--bin" },  -- Cargo command line to build the debug target
                -- args = { 'build' }, --, "--bin=foo"] is another possibility

                -- The rest are optional
                -- env = { RUSTFLAGS = '-Clinker=ld.mold' }, -- Extra environment variables.
                -- problemMatcher = "$rustc",        -- Problem matcher(s) to apply to cargo output.
                -- filter = {                                 -- Filter applied to compilation artifacts.
                --     name = "mylib",
                --     kind = "lib"
                -- }
            },
            cwd = "${workspaceFolder}",
            -- program = '${workspaceFolder}/target/debug/${file}',
            program = function()
                return vim.fn.input("Path to executable: ",
                    vim.fn.getcwd() .. "/target/debug/", "file")
            end,
            stopOnEntry = false,
        },
    })
end

local function pick_runtime_executable()
    return coroutine.create(function(dap_run_co)
        vim.ui.input({ prompt = "Executable> ", completion = "shellcmd" },
            function(input)
                if not input or input == "" then
                    coroutine.resume(dap_run_co, require("dap").ABORT)
                    return
                end
                coroutine.resume(dap_run_co, input)
            end)
    end)
end

local function pick_runtime_args()
    return coroutine.create(function(dap_run_co)
        vim.ui.input({ prompt = "Arguments> " }, function(input)
            if not input or input == "" then
                coroutine.resume(dap_run_co, require("dap").ABORT)
                return
            end
            local input_array = vim.split(input, " ", { trimempty = true })
            coroutine.resume(dap_run_co, input_array)
        end)
    end)
end

local function pick_package_json_script_executable()
    return coroutine.create(function(dap_run_co)
        local items = { "npm", "yarn" }
        vim.ui.select(items, { label = "Runner> " }, function(choice)
            if not choice or choice == "" then
                coroutine.resume(dap_run_co, require("dap").ABORT)
                return
            end
            coroutine.resume(dap_run_co, choice)
        end)
    end)
end

local function get_package_json()
    ---@param message string
    local function log_error(message)
        vim.notify(message, vim.log.levels.ERROR,
            { title = "get_package_json" })
    end

    -- Find the nearest package.json file
    local package_json_path = vim.fn.findfile("package.json", ".;")

    if package_json_path ~= "" then
        -- Read the contents of package.json
        local content = vim.fn.readfile(package_json_path)
        local json_str = table.concat(content, "\n")

        -- Parse the JSON content
        local ok, parsed = pcall(vim.json.decode, json_str)

        if ok then
            return parsed
        else
            log_error('could not decode JSON at "' .. package_json_path .. '"')
        end
    else
        log_error("could not find package.json")
    end
end

---@return string[]
local function get_package_json_script_names()
    ---@param message string
    local function log_error(message)
        vim.notify(message, vim.log.levels.ERROR,
            { title = "get_package_json_script_names" })
    end
    local script_names = {}

    local package_json = get_package_json()
    if not package_json then
        log_error("could not find package.json")
        return {}
    end
    if package_json.scripts then
        for script_name, _ in pairs(package_json.scripts) do
            table.insert(script_names, script_name)
        end
    else
        log_error("could not find scripts in package.json")
    end

    return script_names
end

local function pick_package_json_script_args()
    return coroutine.create(function(dap_run_co)
        local script_names = get_package_json_script_names()
        if not script_names or #script_names == 0 then
            coroutine.resume(dap_run_co, require("dap").ABORT)
        end
        vim.notify("script_names: " .. table.concat(script_names, ", "))
        vim.ui.select(script_names, { label = "Script> " }, function(choice)
            if not choice or choice == "" then
                coroutine.resume(dap_run_co, require("dap").ABORT)
                return
            end
            local result = { "run", choice }
            coroutine.resume(dap_run_co, result)
        end)
    end)
end

local function config_javascript()
    local dap_utils = require("dap.utils")

    local adapter_key = "pwa-node"
    ---@type dap.Adapter
    local js_adapter = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
            command = "node",
            -- 💀 Make sure to update this path to point to your installation
            args = {
                require("mason-registry").get_package("js-debug-adapter")
                :get_install_path()
                .. "/js-debug/src/dapDebugServer.js",
                "${port}",
            },
        },
    }
    ---@type dap.Configuration[]
    local js_configs = {
        {
            type = adapter_key,
            request = "attach",
            name = "Attach",
            processId = dap_utils.pick_process,
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
        },
        {
            type = adapter_key,
            request = "launch",
            name = "Launch package.json script",
            runtimeExecutable = pick_package_json_script_executable,
            runtimeArgs = pick_package_json_script_args,
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
        },
        {
            type = adapter_key,
            request = "launch",
            name = "Launch command",
            runtimeExecutable = pick_runtime_executable,
            runtimeArgs = pick_runtime_args,
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
        },
        {
            type = adapter_key,
            request = "launch",
            name = "Launch this file",
            program = "${file}",
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
        },
        {
            type = adapter_key,
            request = "launch",
            name = "Pick file",
            program = dap_utils.pick_file,
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
        },
    }

    set_adapter_if_not_defined(adapter_key, js_adapter)
    for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
        set_configs_if_not_defined(language, js_configs)
    end
end



local icons = {
    Stopped             = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
    Breakpoint          = " ",
    BreakpointCondition = " ",
    BreakpointRejected  = { " ", "DiagnosticError" },
    LogPoint            = ".>",
}

---@class DapUserCommand
---@field name string
---@field cmd fun(): nil
---@field desc string

---@type DapUserCommand[]
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

    config_javascript();
    config_rust();
end

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
