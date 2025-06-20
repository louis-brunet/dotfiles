local function pick_runtime_executable()
    return require("user.config.dap.utils").input("Executable> ",
        { completion = "shellcmd" })
end


local function pick_runtime_args()
    return require("user.config.dap.utils").input("Arguments> ",
        {
            on_choice = function(input)
                if not input or input == "" then
                    return nil
                end
                local input_array = vim.split(input, " ", { trimempty = true })
                return input_array
            end,
        })
end

local function pick_package_json_script_executable()
    local js_utils = require("user.utils.javascript")
    return coroutine.create(function(dap_run_co)
        local js_utils = require("user.utils.javascript")
        js_utils.select_package_manager(function(choice)
            if choice == nil then
                coroutine.resume(dap_run_co, require("dap").ABORT)
            else
                local result = { "run", choice }
                coroutine.resume(dap_run_co, result)
            end
        end)
    end)
end


---@return thread
local function pick_package_json_script_args()
    return coroutine.create(function(dap_run_co)
        local js_utils = require("user.utils.javascript")
        js_utils.select_package_json_script(function(choice)
            if choice == nil then
                coroutine.resume(dap_run_co, require("dap").ABORT)
            else
                local result = { "run", choice }
                coroutine.resume(dap_run_co, result)
            end
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
            command = vim.fn.exepath("js-debug-adapter"),
            args = { "${port}" },
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

    local dap_config_utils = require("user.config.dap.utils")
    dap_config_utils.set_adapter_if_not_defined(adapter_key, js_adapter)
    for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
        dap_config_utils.set_configs_if_not_defined(language, js_configs)
    end
end



---@type UserDapConfigLanguageModule
local M = { configure = config_javascript }
return M
