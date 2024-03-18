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


-- ---@class OlloumaSubcommandConfig
-- ---@field run fun(): nil
---@alias OlloumaSubcommand fun(): nil


---@class OlloumaConfig
---@field chat OlloumaChatConfig
---@field api OlloumaApiConfig
---@field model_actions OlloumaModelActionConfig[]
---@field user_command_subcommands table<string, OlloumaSubcommand>

---@class OlloumaPartialConfig
---@field chat? OlloumaPartialChatConfig
---@field api? OlloumaPartialApiConfig
---@field model_actions? OlloumaModelActionConfig[]
---@field user_command_subcommands? table<string, OlloumaSubcommand>


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
                    local util = require('ollouma.util')

                    ui:start(model)

                    vim.api.nvim_buf_create_user_command(ui.state.prompt.buffer, "OlloumaSend", function()
                        local prompt = vim.api.nvim_buf_get_lines(ui.state.prompt.buffer, 0, -1, false)

                        util.buf_append_lines(ui.state.output.buffer, { '', '<!------ Prompt ------' })
                        util.buf_append_lines(ui.state.output.buffer, prompt)
                        util.buf_append_lines(ui.state.output.buffer, { '--------------------->', '' })

                        Generate.generate(
                        ---@type OlloumaGenerateOptions
                            {
                                model = model,
                                prompt = vim.fn.join(prompt, '\n'),
                                api_url = config.api.generate_url,
                                on_response = function(partial_response)
                                    util.buf_append_string(ui.state.output.buffer, partial_response)

                                    local output_cursor = vim.api.nvim_win_get_cursor(ui.state.output.window)

                                    local last_line_idx = vim.api.nvim_buf_line_count(ui.state.output.buffer)
                                    if output_cursor[1] == last_line_idx - 1 then
                                        local last_line = vim.api.nvim_buf_get_lines(ui.state.output.buffer, -2, -1, false)
                                        local last_column_idx = math.max(0, #last_line - 1)
                                        vim.api.nvim_win_set_cursor(ui.state.output.window, {last_line_idx, last_column_idx})
                                    end
                                end
                            }
                        )
                    end, {})
                end
            },
        },

        user_command_subcommands = {
            select = function()
                require('ollouma').select()
            end,

            last = function()
                require('ollouma').last_model_action()
            end,

            empty = function()
                require('ollouma.util.ui'):empty_buffers()
            end,

            close = function()
                require('ollouma.util.ui'):close()
            end,
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
