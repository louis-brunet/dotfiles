local M = {}

---@param opts {bufnr: number|nil, method: string|nil}|nil
---@return vim.lsp.Client[]
function M.get_buffer_lsp_clients(opts)
    opts = opts or {}
    ---@type vim.lsp.get_clients.Filter
    local client_filter = {
        bufnr = opts.bufnr or vim.api.nvim_get_current_buf(),
        method = opts.method,
    }

    local clients
    if vim.lsp.get_clients then
        clients = vim.lsp.get_clients(client_filter)
    else
        -- NOTE: vim.lsp.get_active_clients is deprecated in nvim 0.10
        clients = vim.lsp.get_active_clients(client_filter)
    end

    return clients
end

---@param clients vim.lsp.Client[]
---@param client_names string[]
function M.contains_any_client(clients, client_names)
    return vim.tbl_contains(clients, function(c)
        return vim.tbl_contains(client_names, c.name)
    end, { predicate = true })
end

return M
