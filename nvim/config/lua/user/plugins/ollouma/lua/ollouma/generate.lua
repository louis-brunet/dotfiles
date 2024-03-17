---@class OlloumaGenerateOptions
---@field model string
---@field prompt string|nil
---@field api_url string
---@field on_response fun(partial_response: string): nil

---@class OlloumaGenerateResponseLine
---@field response string
---@field done boolean
---@field model string
---@field created_at string

---@class OlloumaGenerateViewState
---@field buffer? number
---@field window? number

---@class OlloumaGenerateModule
---@field view OlloumaGenerateViewState
local M = {}


---@param opts OlloumaGenerateOptions
function M.generate(opts)
    vim.validate({
        model = { opts.model, 'string' },
        prompt = { opts.prompt, { 'string', 'nil' } },
        api_url = { opts.api_url, 'string' },
        on_response = { opts.on_response, 'function' },
    })

    local prompt = opts.prompt
    if not prompt or #prompt == 0 then
        prompt = vim.fn.input({ prompt = 'Prompt [' .. opts.model .. ']: ', text = "n" })

        if not prompt or #prompt == 0 then
            return
        end
    end

    local api = require('ollouma.util.api-client')
    api.stream_response(
        opts.api_url,

        { model = opts.model, prompt = prompt },

        ---@param response OlloumaGenerateResponseChunkDto
        function(response)
            if response.done then
                -- TODO: any cleanup ?
                return
            end

            -- if response.response then
            vim.schedule(function()
                opts.on_response(response.response)
            end)
            -- end
        end
    )
end

return M
