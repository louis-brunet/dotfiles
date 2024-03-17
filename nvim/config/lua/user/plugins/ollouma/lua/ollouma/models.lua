---@class OlloumaModelListOpts
---@field timeout_ms? integer
---@field poll_interval_ms? integer

local M = {}

---@param url string
---@return string[]|nil
function M.list_models(url)
    local api = require('ollouma.util.api-client')

    return api.find_all_models(url)
end

---@param url string
---@param on_select fun(string): nil
function M.select_model(url, on_select)
    vim.validate({ on_select = { on_select, 'function' } })

    local models = M.list_models(url)

    if not models then
        vim.notify('ollouma: no models found, cannot select', vim.log.levels.INFO)

        return
    end

    vim.ui.select(
        models,

        {
            prompt = 'Available models',
            -- format_item = function(item)
            --     return 'FORMATTED -- ' .. item
            -- end
        },

        function(item, _)
            on_select(item)
        end
    )
end

return M
