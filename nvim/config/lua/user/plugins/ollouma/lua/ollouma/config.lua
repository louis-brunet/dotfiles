---@class OlloumaChatConfig
---@field model string
---@field system_prompt string

---@class OlloumaPartialChatConfig
---@field model? string
---@field system_prompt? string


---@class OlloumaApiConfig
---@field generate_url string
---@field chat_url string
---@field models_url string

---@class OlloumaPartialApiConfig
---@field generate_url? string
---@field chat_url? string
---@field models_url? string


---@class OlloumaModelActionConfig
---@field name string
---@field on_select fun(current_model: string): nil


---@class OlloumaConfig
---@field chat OlloumaChatConfig
---@field api OlloumaApiConfig
---@field model_actions OlloumaModelActionConfig[]

---@class OlloumaPartialConfig
---@field chat? OlloumaPartialChatConfig
---@field api? OlloumaPartialApiConfig
---@field model_actions? OlloumaModelActionConfig[]


---@class OlloumaConfigModule
---@field default_config fun(): OlloumaConfig
---@field extend_config fun(current_config?: OlloumaConfig, partial_config?: OlloumaPartialConfig): OlloumaConfig
local M = {}

function M.default_config()
    ---@type OlloumaConfig
    return {
        chat = {
            model = 'mistral',
            system_prompt = '',
        },

        api = {
            generate_url = '127.0.0.1:11434/api/generate',
            chat_url = '127.0.0.1:11434/api/chat',
            models_url = '127.0.0.1:11434/api/tags',
        },

        model_actions = {
            {
                name = 'Generate',
                on_select = function(model)
                    local Generate = require('ollouma.generate')
                    local config = require('ollouma').config
                    local ui = require('ollouma.util.ui')

                    ui:start(model)

                    vim.api.nvim_buf_create_user_command(ui.state.prompt.buffer, "OlloumaSend", function()
                        local prompt = vim.api.nvim_buf_get_lines(ui.state.prompt.buffer, 0, -1, false)

                        vim.api.nvim_buf_set_lines(ui.state.output.buffer, -1, -1, false, { '', '<!-- ## Prompt ##' })
                        vim.api.nvim_buf_set_lines(ui.state.output.buffer, -1, -1, false, prompt)
                        vim.api.nvim_buf_set_lines(ui.state.output.buffer, -1, -1, false, { '-->', '' })

                        Generate.generate(
                        ---@type OlloumaGenerateOptions
                            {
                                model = model,
                                prompt = vim.fn.join(prompt, '\n'),
                                api_url = config.api.generate_url,
                                on_response = function(partial_response)
                                    local last_line = vim.api.nvim_buf_get_lines(ui.state.output.buffer, -2, -1, false)[1]
                                    local concatenated = (last_line or "") .. (partial_response or "")
                                    local new_lines = vim.split(concatenated, '\n', { plain = true })

                                    vim.api.nvim_buf_set_lines(
                                        ui.state.output.buffer, -2, -1, false,
                                        new_lines
                                    )
                                end
                            }
                        )
                    end, {})
                end
            },
        },
    }
end

--- Extend the current config with the given partial config. If the current
--- config is nil, then use default settings as the current config.
function M.extend_config(current_config, partial_config)
    current_config = current_config or M.default_config()
    if not partial_config then
        return current_config
    end

    return vim.tbl_deep_extend('force', current_config, partial_config)
end

return M
