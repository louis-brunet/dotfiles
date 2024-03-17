---@class Ollouma
---@field config OlloumaConfig
local M = {}

---@param opts? OlloumaPartialConfig
function M.setup(opts)
    local Config = require('ollouma.config')
    M.config = Config.extend_config(M.config, opts)
end

-- ---@param model? string
-- ---@param system_prompt? string
-- function M.chat(model, system_prompt)
--     local Chat = require('ollouma.chat')
--     Chat.start({
--         model = model or M.config.chat.model,
--         system_prompt = system_prompt or M.config.chat.system_prompt,
--     })
-- end

---@param model string
function M.select_model_action(model)
    vim.validate({ model = { model, 'string' } })

    if #M.config.model_actions == 0 then
        vim.notify('No actions to pick from', vim.log.levels.WARN)
        return
    end

    vim.ui.select(
        M.config.model_actions,

        {
            prompt = 'Actions [' .. model .. ']',
            format_item = function(item) return item.name end
        },

        ---@param item OlloumaModelActionConfig
        ---@param _ integer index
        function(item, _) if item then item.on_select(model) end end
    )
end

function M.select()
    local Models = require('ollouma.models')

    Models.select_model(M.config.api.models_url, function(model)
        M.select_model_action(model)
    end)
end

return M
