---@class OlloumaState
---@field last_action? { model: string, model_action: OlloumaModelActionConfig }

---@class Ollouma
---@field config OlloumaConfig
---@field _state OlloumaState
local M = {}

---@param partial_config? OlloumaPartialConfig
function M.setup(partial_config)
    local Config = require('ollouma.config')

    M.config = Config.extend_config(M.config, partial_config)
    M._state = {}

    local subcommands = M.config.user_command_subcommands or {}
    ---@type string[]
    local subcommand_names = vim.tbl_keys(subcommands)

    vim.api.nvim_create_user_command('Ollouma',
        function(cmd_opts)
            local arg = cmd_opts.fargs[1]
            if not arg then
                require('ollouma').select()
            else
                local subcommand = subcommands[arg]
                if not subcommand then
                    return
                end
                subcommand()
            end
        end,
        {
            nargs = '?',
            complete = function(ArgLead, CmdLine, CursorPos)
                return vim.tbl_filter(
                ---@param name string
                    function(name)
                        local match = name:match('^' .. ArgLead)
                        return not not match
                    end,
                    subcommand_names
                )
            end,
        }
    )
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
        function(item, _)
            if item then
                M._state.last_action = { model = model, model_action = item }

                local ok, err = pcall(item.on_select, model)
                if not ok then
                    vim.notify('Could not call model action: ' .. err, vim.log.levels.WARN)
                end
            end
        end
    )
end

function M.last_model_action()
    local action = M._state.last_action
    if action then
        local ok, err = pcall(action.model_action.on_select, action.model)
        if not ok then
            vim.notify('Could not call model action: ' .. err, vim.log.levels.WARN)
        end
    else
        vim.notify('Last model action not found', vim.log.levels.WARN)
    end
end

function M.select()
    local Models = require('ollouma.models')

    Models.select_model(M.config.api.models_url, function(model)
        M.select_model_action(model)
    end)
end

return M
