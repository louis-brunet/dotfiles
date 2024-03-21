---@class OlloumaGenerateOptions
---@field model string
---@field prompt string|nil
---@field api_url string
---@field on_response fun(partial_response: string): nil
---@field on_response_end fun(): nil

---@class OlloumaGenerateModule
local M = {}


---@param opts OlloumaGenerateOptions
---@return fun():nil stop_generation function to call when generation should be halted
function M.start_generation(opts)
    vim.validate({
        model = { opts.model, 'string' },
        prompt = { opts.prompt, { 'string', 'nil' } },
        api_url = { opts.api_url, 'string' },
        on_response = { opts.on_response, 'function' },
        on_response_end = { opts.on_response_end, 'function' },
    })

    local api = require('ollouma.util.api-client')
    local log = require('ollouma.util.log')
    local prompt = opts.prompt

    if not prompt or #prompt == 0 then
        prompt = vim.fn.input({ prompt = 'Prompt [' .. opts.model .. ']: ', text = "n" })

        if not prompt or #prompt == 0 then
            log.warn('empty prompt, aborting')
            return function() end
        end
    end

    local api_close_generation = api.stream_response(
        opts.api_url,

        { model = opts.model, prompt = prompt },

        ---@param response OlloumaGenerateResponseChunkDto
        function(response)
            if response.done then
                if opts.on_response_end then
                    vim.schedule(opts.on_response_end)
                end
                -- TODO: any cleanup/final actions ?
                return
            end

            vim.schedule(function()
                opts.on_response(response.response)
            end)
        end
    )

    return function()
        api_close_generation()
    end
end

---@param model string
---@param api_url string|nil
function M.start_generate_ui(model, api_url)
    vim.validate({
        model = { model, 'string' },
        api_url = { api_url, { 'string', 'nil' } },
    })

    ---@type OlloumaConfig
    local config = require('ollouma').config
    -- TODO: model = model or config.generate.model

    ---@type OlloumaGenerateUi
    local ui = require('ollouma.generate.ui')
    -- local util = require('ollouma.util')

    ui.start_ui(model, api_url or config.api.generate_url, {
        { label = 'Send',  function_name = 'v:lua._G._ollouma_winbar_send' },
        { label = 'Empty', function_name = 'v:lua._G._ollouma_winbar_reset' },
        { label = 'Close', function_name = 'v:lua._G._ollouma_winbar_close' },
    })

    -- ui:start(model, {
    --     commands = {
    --         OlloumaSend = {
    --             rhs = function()
    --                 local prompt = ui:get_prompt()
    --
    --                 ui:output_write_lines({ '', '<!------ Prompt ------' })
    --                 ui:output_write_lines(prompt)
    --                 ui:output_write_lines({ '--------------------->', '' })
    --
    --                 ---@type OlloumaGenerateOptions
    --                 local generate_opts = {
    --                     model = model,
    --                     prompt = vim.fn.join(prompt, '\n'),
    --                     api_url = config.api.generate_url,
    --                     on_response = function(partial_response)
    --                         ui:output_write(partial_response)
    --
    --                         if not ui.state.output.window or not vim.api.nvim_win_is_valid(ui.state.output.window) then
    --                             return
    --                         end
    --
    --                         -- if cursor is on second to last line, then
    --                         -- move it to the last line
    --                         local output_cursor = vim.api.nvim_win_get_cursor(ui.state.output.window)
    --                         local last_line_idx = vim.api.nvim_buf_line_count(ui.state.output.buffer)
    --
    --                         if output_cursor[1] == last_line_idx - 1 then
    --                             local last_line = vim.api.nvim_buf_get_lines(
    --                                 ui.state.output.buffer,
    --                                 -2, -1, false
    --                             )
    --                             local last_column_idx = math.max(0, #last_line - 1)
    --
    --                             vim.api.nvim_win_set_cursor(
    --                                 ui.state.output.window,
    --                                 { last_line_idx, last_column_idx }
    --                             )
    --                         end
    --                     end,
    --                     on_response_end = function()
    --                         vim.api.nvim_buf_del_user_command(ui.state.prompt.buffer, 'OlloumaGenStop')
    --                         vim.api.nvim_buf_del_user_command(ui.state.output.buffer, 'OlloumaGenStop')
    --                     end
    --                 }
    --                 local stop_generation = generate_module.start_generation(generate_opts)
    --
    --                 local function stop()
    --                     stop_generation()
    --                     generate_opts.on_response_end()
    --                 end
    --
    --                 vim.api.nvim_buf_create_user_command(
    --                     ui.state.prompt.buffer,
    --                     'OlloumaGenStop',
    --                     stop,
    --                     {}
    --                 )
    --                 vim.api.nvim_buf_create_user_command(
    --                     ui.state.output.buffer,
    --                     'OlloumaGenStop',
    --                     stop,
    --                     {}
    --                 )
    --             end,
    --             opts = {},
    --         },
    --     },
    --
    --     winbar_items = {
    --         { label = 'Send',  function_name = 'v:lua._G._ollouma_winbar_send' },
    --         { label = 'Empty', function_name = 'v:lua._G._ollouma_winbar_reset' },
    --         { label = 'Close', function_name = 'v:lua._G._ollouma_winbar_close' },
    --     },
    -- })
end

return M
