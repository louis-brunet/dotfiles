---@class OlloumaUiItem
---@field buffer integer|nil
---@field window integer|nil

---@class OlloumaUiState
---@field prompt OlloumaUiItem
---@field output OlloumaUiItem

---@class OlloumaUiBufferCommand
---@field rhs string|fun():nil
---@field opts table

---@alias OlloumaUiStartOptsCommands table<string, OlloumaUiBufferCommand>

---@class OlloumaUiStartOpts
---@field commands OlloumaUiStartOptsCommands
--TODO:---@field keymaps OlloumaUiStartOptsKeymaps

_G._ollouma_winbar_send = function()
    require('ollouma.util.log').warn('hi from _G._ollouma_winbar_send')
    vim.cmd('OlloumaSend')
end

_G._ollouma_winbar_reset = function()
    require('ollouma.util.ui'):empty_buffers()
end

---@class OlloumaUi
---@field state OlloumaUiState
local M = {
    state = {
        prompt = {},
        output = {},
    },
}

---@param model_name string
---@param opts? OlloumaUiStartOpts
function M:start(model_name, opts)
    opts = opts or {}

    self.state.prompt.buffer = self.state.prompt.buffer or vim.api.nvim_create_buf(false, true)
    self.state.output.buffer = self.state.output.buffer or vim.api.nvim_create_buf(false, true)

    if opts.commands then
        for command_name, cmd in pairs(opts.commands) do
            vim.validate({
                command_name = { command_name, 'string' },
                rhs = { cmd.rhs, { 'string', 'function' } },
                opts = { cmd.opts, { 'table', 'nil' } },
            })

            vim.api.nvim_buf_create_user_command(
                self.state.prompt.buffer,
                command_name,
                cmd.rhs,
                cmd.opts or {}
            )
        end
    end

    vim.api.nvim_buf_set_name(self.state.prompt.buffer, 'PROMPT [' .. model_name .. ']')
    vim.api.nvim_buf_set_name(self.state.output.buffer, 'OUTPUT [' .. model_name .. ']')

    self:open_windows()

    vim.api.nvim_buf_set_option(self.state.prompt.buffer, 'ft', 'markdown')
    vim.api.nvim_buf_set_option(self.state.output.buffer, 'ft', 'markdown')

    vim.api.nvim_win_set_option(self.state.prompt.window, 'winbar', '%@v:lua._G._ollouma_winbar_send@Send%X %@v:lua._G._ollouma_winbar_reset@Reset%X')
end

function M:are_buffers_valid()
    if not self.state.prompt.buffer or not vim.api.nvim_buf_is_valid(self.state.prompt.buffer) then
        return false
    end
    if not self.state.output.buffer or not vim.api.nvim_buf_is_valid(self.state.output.buffer) then
        return false
    end
    return true
end

function M:open_windows()
    if not M:are_buffers_valid() then
        require('ollouma.util.log').error('cannot open windows, buffer is invalid')
        -- error()
        return
    end

    if not self.state.output.window or not vim.api.nvim_win_is_valid(self.state.output.window) then
        vim.cmd.vsplit()
        self.state.output.window = vim.api.nvim_get_current_win()
    end

    if not self.state.prompt.window or not vim.api.nvim_win_is_valid(self.state.prompt.window) then
        vim.api.nvim_set_current_win(self.state.output.window)
        vim.cmd.split()
        self.state.prompt.window = vim.api.nvim_get_current_win()
    end

    vim.api.nvim_win_set_buf(self.state.prompt.window, self.state.prompt.buffer)
    vim.api.nvim_win_set_buf(self.state.output.window, self.state.output.buffer)

    vim.api.nvim_set_current_win(self.state.prompt.window)
end

function M:empty_buffers()
    local emptied_any = false

    if self.state.output.buffer and vim.api.nvim_buf_is_loaded(self.state.output.buffer) then
        emptied_any = true
        vim.api.nvim_buf_set_lines(self.state.output.buffer, 0, -1, false, { '' })
    end

    if self.state.prompt.buffer and vim.api.nvim_buf_is_loaded(self.state.prompt.buffer) then
        emptied_any = true
        vim.api.nvim_buf_set_lines(self.state.prompt.buffer, 0, -1, false, { '' })
    end


    if not emptied_any then
        require('ollouma.util.log').warn('no buffers to empty')
    end
end

function M:output_write_lines(lines)
    local util = require('ollouma.util')

    util.buf_append_lines(self.state.output.buffer, lines)
end

function M:output_write(lines)
    local util = require('ollouma.util')

    util.buf_append_string(self.state.output.buffer, lines)
end

---@return string[] prompt_lines the lines currently in the prompt buffer
function M:get_prompt()
    return vim.api.nvim_buf_get_lines(self.state.prompt.buffer, 0, -1, false)
end

--- Close any open windows
function M:close()
    if self.state.prompt.window and vim.api.nvim_win_is_valid(self.state.prompt.window) then
        vim.api.nvim_win_close(self.state.prompt.window, false)
    end
    if self.state.output.window and vim.api.nvim_win_is_valid(self.state.output.window) then
        vim.api.nvim_win_close(self.state.output.window, false)
    end

    self.state.prompt.window = nil
    self.state.output.window = nil
end

return M
