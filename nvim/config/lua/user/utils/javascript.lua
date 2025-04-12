---@param string1 string
---@param string2 string
---@return boolean
local function sort_alphabetical(string1, string2)
    return string1:lower() < string2:lower()
end

local function find_nearest_package_json()
    local package_json_path = vim.fn.findfile("package.json", ".;")
    vim.validate('package_json_path', package_json_path, 'string')
    return package_json_path
end


---@class UserUtilsJavascript
local M = {}

---@class UserUtilsJavascriptScriptSortPatterns
---@field scripts_first string[]
---@field scripts_other string[]
---@field scripts_last string[]

---@type UserUtilsJavascriptScriptSortPatterns
M.default_package_json_script_patterns = {
    scripts_first = { "debug" },
    scripts_other = {},
    scripts_last = {
        "preinstall",
        "postinstall",
        "postpublish",
        "prepublish",
        "prepublishOnly",
        "prepare",
        "prepack",
        "postpack",
        "dependencies",
    },
}

---@class UserUtilsJavascriptPackageManager
---@field name string
---@field lock_file string

--- NOTE: order in this table determines priority
---@type UserUtilsJavascriptPackageManager[]
M.detectable_packager_managers = {
    { name = "yarn", lock_file = "yarn.lock" },
    { name = "pnpm", lock_file = "pnpm-lock.yaml" },
    { name = "npm",  lock_file = "package-lock.json" },
}

---Find and parse the closest package.json in a parent directory
---@return unknown|nil package_json decoded JSON inside the found file, or nil
function M.parse_package_json()
    ---@param message string
    local function log_error(message)
        vim.notify(message, vim.log.levels.ERROR,
            { title = "parse_package_json" })
    end

    -- Find the nearest package.json file
    local package_json_path = find_nearest_package_json()

    if package_json_path ~= nil and package_json_path ~= "" then
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

    return nil
end

---@param package_json unknown|nil a decoded package.json, the result of `parse_package_json()`
---@return string|nil
function M.detect_package_manager(package_json)
    if package_json and package_json.packageManager then
        assert(type(package_json.packageManager) == "string")
        ---@type string
        local package_manager_from_json = package_json.packageManager
        -- for package_manager, package_manager_lock_file in ipairs(package_managers) do
        for _, package_manager_info in ipairs(M.detectable_packager_managers) do
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

---@return string[]
function M.get_package_json_script_names()
    ---@param message string
    local function log_error(message)
        vim.notify(message, vim.log.levels.ERROR,
            { title = "get_package_json_script_names" })
    end
    local script_names = {}
    local package_json = M.parse_package_json()
    if not package_json then
        log_error("could not find package.json")
        return script_names
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

---@param script_names string[]
---@param opts? { sort_patterns?: UserUtilsJavascriptScriptSortPatterns }
---@return string[]
function M.sort_package_json_scripts(script_names, opts)
    opts = opts or {}
    opts.sort_patterns = opts.sort_patterns or {}

    ---@type UserUtilsJavascriptScriptSortPatterns
    local sort_patterns = {
        scripts_first = opts.sort_patterns.scripts_first or
            M.default_package_json_script_patterns.scripts_first,
        scripts_other = opts.sort_patterns.scripts_other or
            M.default_package_json_script_patterns.scripts_other,
        scripts_last = opts.sort_patterns.scripts_last or
            M.default_package_json_script_patterns.scripts_last,
    }

    ---@type table<string, string[]>
    local sorted = { scripts_first = {}, scripts_other = {}, scripts_last = {} }

    for _, script_name in ipairs(script_names) do
        local inserted = false
        for pattern_list_key, pattern_list in pairs(sort_patterns) do
            if inserted then
                break
            end
            for _, pattern in ipairs(pattern_list) do
                if inserted then
                    break
                end
                if script_name:find(pattern) then
                    table.insert(sorted[pattern_list_key], script_name)
                    inserted = true
                end
            end
        end
        if not inserted then
            table.insert(sorted.scripts_other, script_name)
        end
    end

    local all_scripts = {}
    for _, scripts in pairs(sorted) do
        table.sort(scripts, sort_alphabetical)
        for _, script_name in ipairs(scripts) do
            table.insert(all_scripts, script_name)
        end
    end
    return all_scripts
end

---@param on_done fun(result: string|nil):nil
function M.select_package_json_script(on_done)
    local js_utils = require("user.utils.javascript")
    local script_names = js_utils.get_package_json_script_names()
    -- vim.notify("scripts: " .. vim.inspect(script_names))
    if not script_names or #script_names == 0 then
        on_done(nil)
        return;
    end
    script_names = js_utils.sort_package_json_scripts(script_names)
    -- vim.notify("sorted scripts: " .. vim.inspect(script_names))
    vim.ui.select(script_names, { label = "Script> " }, function(choice)
        if not choice or choice == "" then
            on_done(nil)
            return
        end
        -- local result = { "run", choice }
        on_done(choice)
    end)
end

---@param on_done fun(result: string|nil):nil
---@param opts? { disable_detection?: boolean }
function M.select_package_manager(on_done, opts)
    opts = opts or {}
    local package_json = M.parse_package_json()
    if not opts.disable_detection then
        local detected = M.detect_package_manager(package_json)
        if detected then
            vim.notify("Detected package manager: " .. detected)
            on_done(detected)
            return
        end
    end
    local ordered_choices = {}
    for _, package_manager_info in ipairs(M.detectable_packager_managers) do
        table.insert(ordered_choices, package_manager_info.name)
    end
    vim.ui.select(ordered_choices, { label = "Runner> " }, function(choice)
        if not choice or choice == "" then
            on_done(nil)
            return
        end
        on_done(choice)
    end)
end

---@class UserUtilsJavascriptRunPackageJsonScriptOptions
---@field on_done? fun(exec_command: string[]|nil, completed: vim.SystemCompleted|nil):nil
---@field system_opts? vim.SystemOpts

---@param opts? UserUtilsJavascriptRunPackageJsonScriptOptions
---@return vim.SystemObj|nil system_obj the executed command
function M.run_package_json_script(opts)
    opts = opts or {}
    opts.system_opts = opts.system_opts or {}
    if opts.system_opts.text ==nil then
        opts.system_opts.text = true
    end
    opts.on_done = opts.on_done or function() end
    M.select_package_manager(function(package_manager)
        if package_manager == nil or package_manager == "" then
            opts.on_done(nil)
            return nil
        end

        M.select_package_json_script(function(package_json_script)
            if package_json_script == nil or package_json_script == "" then
                opts.on_done(nil)
                return nil
            end

            local exec_command = { package_manager, "run", package_json_script }

            -- TODO: tmux or some other nicer display
            -- vim.notify(
            --     "TODO: execute this command in tmux? what to do when no tmux? " ..
            --     vim.inspect(exec_command), vim.log.levels.WARN,
            --     { title = "run_package_json_script" })

            local command_runner = require('user.utils.command-runner')
            command_runner.run(exec_command)
        end)
    end)
    opts.on_done(nil)
    return nil
end

function M.open_package_json()
    local package_json_path = find_nearest_package_json()
    if not package_json_path or package_json_path == "" then
        vim.notify("No package.json found", vim.log.levels.WARN, { title = "open_package_json" })
        return
    end
    vim.cmd.edit(package_json_path)
end

return M
