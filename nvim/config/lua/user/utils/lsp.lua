local M = {}

---@param opts {bufnr: number|nil}|nil
---@return vim.lsp.Client[]
function M.get_buffer_lsp_clients(opts)
    opts = opts or {}
    local client_filter = { bufnr = opts.bufnr or vim.api.nvim_get_current_buf() }

    local clients
    if vim.lsp.get_clients then
        clients = vim.lsp.get_clients(client_filter)
    else
        -- vim.lsp.get_active_clients is deprecated in nvim 0.10
        clients = vim.lsp.get_active_clients(client_filter)
    end

    return clients
end

return M
