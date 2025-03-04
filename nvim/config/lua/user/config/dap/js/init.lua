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

local function parse_package_json()
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
        log_error("could not find package.json in any parent directory")
    end
end

--- NOTE: order in this table determines priority
local detectable_packager_managers = {
    { name = "yarn", lock_file = "yarn.lock" },
    { name = "pnpm", lock_file = "pnpm-lock.yaml" },
    { name = "npm",  lock_file = "package-lock.json" },
}

---@param package_json unknown|nil
---@return string|nil
local function detect_package_manager(package_json)
    if package_json and package_json.packageManager then
        assert(type(package_json.packageManager) == "string")
        ---@type string
        local package_manager_from_json = package_json.packageManager
        -- for package_manager, package_manager_lock_file in ipairs(package_managers) do
        for _, package_manager_info in ipairs(detectable_packager_managers) do
            local found_package_manager = package_manager_from_json:find(
                package_manager_info.name)
            local found_lock_file = vim.fn.findfile(
                package_manager_info.lock_file,
                ".;"
            )
            if found_package_manager or (found_lock_file and found_lock_file ~= "") then
                return package_manager_info.name
            end
        end
    end
    return nil
end

local function pick_package_json_script_executable()
    return coroutine.create(function(dap_run_co)
        local package_json = parse_package_json()
        local detected = detect_package_manager(package_json)
        if detected then
            vim.notify("Detected package manager: " .. detected)
            coroutine.resume(dap_run_co, detected)
            return
        end
        local ordered_choices = {}
        for _, package_manager_info in ipairs(detectable_packager_managers) do
            table.insert(ordered_choices, package_manager_info.name)
        end
        vim.ui.select(ordered_choices, { label = "Runner> " }, function(choice)
            if not choice or choice == "" then
                coroutine.resume(dap_run_co, require("dap").ABORT)
                return
            end
            coroutine.resume(dap_run_co, choice)
        end)
    end)
end


---@return string[]
local function get_package_json_script_names()
    ---@param message string
    local function log_error(message)
        vim.notify(message, vim.log.levels.ERROR,
            { title = "get_package_json_script_names" })
    end
    local script_names = {}
    local package_json = parse_package_json()
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

---@param string1 string
---@param string2 string
---@return boolean
local function sort_alphabetical(string1, string2)
    return string1:lower() < string2:lower()
end

---@param script_names string[]
local function sort_package_json_scripts(script_names)
    local scripts_first = {}
    local scripts_other = {}
    local scripts_last = {}

    for _, script_name in ipairs(script_names) do
        if script_name:find("debug") then
            table.insert(scripts_first, script_name)
        elseif script_name == "preinstall"
        or     script_name == "postinstall"
        or     script_name == "postpublish"
        or     script_name == "prepublish"
        or     script_name == "prepublishOnly"
        or     script_name == "prepare"
        or     script_name == "prepack"
        or     script_name == "postpack"
        or     script_name == "dependencies" then
            table.insert(scripts_last, script_name)
        else
            table.insert(scripts_other, script_name)
        end
    end

    local all_scripts = {}
    for _, scripts in ipairs({ scripts_first, scripts_other, scripts_last }) do
        table.sort(scripts, sort_alphabetical)
        for _, script_name in ipairs(scripts) do
            table.insert(all_scripts, script_name)
        end
    end
    return all_scripts
end

---@return thread
local function pick_package_json_script_args()
    return coroutine.create(function(dap_run_co)
        local script_names = get_package_json_script_names()
        if not script_names or #script_names == 0 then
            coroutine.resume(dap_run_co, require("dap").ABORT)
        end
        script_names = sort_package_json_scripts(script_names)
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

    local dap_config_utils = require("user.config.dap.utils")
    dap_config_utils.set_adapter_if_not_defined(adapter_key, js_adapter)
    for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
        dap_config_utils.set_configs_if_not_defined(language, js_configs)
    end
end



---@type UserDapConfigLanguageModule
local M = { configure = config_javascript }
return M
