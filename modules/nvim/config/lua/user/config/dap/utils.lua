local function input_default_on_choice(input)
    if not input or input == "" then
        return nil
    end
    return input
end

---@class UserDapConfigUtils
local M = {}

---@param language string
---@param dap_configs dap.Configuration[]
function M.set_configs_if_not_defined(language, dap_configs)
    local dap = require("dap")

    if not dap.configurations[language] then
        dap.configurations[language] = dap_configs
    end
end

---@param adapter_key string
---@param dap_adapter dap.Adapter|fun(callback: fun(adapter:dap.Adapter), config: dap.Configuration)
function M.set_adapter_if_not_defined(adapter_key, dap_adapter)
    local dap = require("dap")

    if not dap.adapters[adapter_key] then
        dap.adapters[adapter_key] = dap_adapter
    end
end

---@generic Result
---@param prompt string
---@param opts { completion: string|nil, on_choice: (fun(string): Result|nil)|nil }
---@return thread
function M.input(prompt, opts)
    opts = opts or {}
    local on_choice = opts.on_choice or input_default_on_choice
    return coroutine.create(function(dap_run_co)
        vim.ui.input({ prompt = prompt, completion = opts.completion },
            function(input)
                local result = on_choice(input)
                if result == nil then
                    coroutine.resume(dap_run_co, require("dap").ABORT)
                end
                coroutine.resume(dap_run_co, result)
            end)
    end)
end

return M
