---@class OlloumaUiItem
---@field buffer integer|nil
---@field window integer|nil

---@class OlloumaUiState
---@field prompt OlloumaUiItem
---@field output OlloumaUiItem

---@class OlloumaUi
---@field state OlloumaUiState
local M = {
    state = {
        prompt = {},
        output = {},
    }
}

---@param model_name string
function M:start(model_name)
    self.state.prompt.buffer = self.state.prompt.buffer or vim.api.nvim_create_buf(false, true)
    self.state.output.buffer = self.state.output.buffer or vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_name(self.state.prompt.buffer, 'PROMPT [' .. model_name .. ']')
    vim.api.nvim_buf_set_name(self.state.output.buffer, 'OUTPUT [' .. model_name .. ']')

    if not self.state.output.window or not vim.api.nvim_win_is_valid(self.state.output.window) then
        vim.cmd.vsplit()
        self.state.output.window = vim.api.nvim_get_current_win()
    end
    if not self.state.prompt.window or not vim.api.nvim_win_is_valid(self.state.prompt.window) then
        vim.cmd.split()
        self.state.prompt.window = vim.api.nvim_get_current_win()
    end

    vim.api.nvim_win_set_buf(self.state.prompt.window, self.state.prompt.buffer)
    vim.api.nvim_win_set_buf(self.state.output.window, self.state.output.buffer)

    vim.api.nvim_set_current_win(self.state.prompt.window)

    vim.api.nvim_buf_set_option(self.state.prompt.buffer, 'ft', 'markdown')
    vim.api.nvim_buf_set_option(self.state.output.buffer, 'ft', 'markdown')
end

function M:empty_buffers()
    for _, buffer_id in ipairs({ self.state.prompt.buffer, self.state.output.buffer }) do
        if buffer_id and vim.api.nvim_buf_is_loaded(buffer_id) then
            vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, {''})
        end
    end
end

--- Close any open windows
function M:close()
    for _, window_id in ipairs({ self.state.prompt.window, self.state.output.window }) do
        if window_id and vim.api.nvim_win_is_valid(window_id) then
            vim.api.nvim_win_close(window_id, false)
        end
    end

    self.state.prompt.window = nil
    self.state.output.window = nil
end

return M
