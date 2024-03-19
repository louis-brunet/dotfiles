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
            system_prompt = '', -- TODO: chat, system prompt
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
                    -- local util = require('ollouma.util')

                    ui:start(model, {
                        commands = {
                            OlloumaSend = {
                                rhs = function()
                                    local prompt = ui:get_prompt()

                                    ui:output_write_lines({ '', '<!------ Prompt ------' })
                                    ui:output_write_lines(prompt)
                                    ui:output_write_lines({ '--------------------->', '' })

                                    ---@type OlloumaGenerateOptions
                                    local generate_opts = {
                                        model = model,
                                        prompt = vim.fn.join(prompt, '\n'),
                                        api_url = config.api.generate_url,
                                        on_response = function(partial_response)
                                            ui:output_write(partial_response)

                                            if not ui.state.output.window or not vim.api.nvim_win_is_valid(ui.state.output.window) then
                                                return
                                            end

                                            -- if cursor is on second to last line, then
                                            -- move it to the last line
                                            local output_cursor = vim.api.nvim_win_get_cursor(ui.state.output.window)
                                            local last_line_idx = vim.api.nvim_buf_line_count(ui.state.output.buffer)

                                            if output_cursor[1] == last_line_idx - 1 then
                                                local last_line = vim.api.nvim_buf_get_lines(
                                                    ui.state.output.buffer,
                                                    -2, -1, false
                                                )
                                                local last_column_idx = math.max(0, #last_line - 1)

                                                vim.api.nvim_win_set_cursor(
                                                    ui.state.output.window,
                                                    { last_line_idx, last_column_idx }
                                                )
                                            end
                                        end,
                                        on_response_end = function()
                                            vim.api.nvim_buf_del_user_command(ui.state.prompt.buffer, 'OlloumaGenStop')
                                            vim.api.nvim_buf_del_user_command(ui.state.output.buffer, 'OlloumaGenStop')
                                        end
                                    }
                                    local stop_generation = Generate.generate(generate_opts)

                                    local function stop()
                                        stop_generation()
                                        generate_opts.on_response_end()
                                    end

                                    vim.api.nvim_buf_create_user_command(
                                        ui.state.prompt.buffer,
                                        "OlloumaGenStop",
                                        stop,
                                        {}
                                    )
                                    vim.api.nvim_buf_create_user_command(
                                        ui.state.output.buffer,
                                        "OlloumaGenStop",
                                        stop,
                                        {}
                                    )
                                end,
                                opts = {},
                            },
                        },
                    })

                    -- vim.api.nvim_buf_create_user_command(ui.state.prompt.buffer, "OlloumaSend", function()
                    -- end, {})
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
