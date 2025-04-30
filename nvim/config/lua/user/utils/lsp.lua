-- TODO: split custom LSP commands to new lua/user/utils/lsp/ directory

---@param client vim.lsp.Client
---@param old_name string
---@param new_name string
---@return unknown
local function get_rename_file_workspace_edits(client, old_name, new_name)
    local will_rename_params = {
        files = {
            {
                oldUri = vim.uri_from_fname(old_name),
                newUri = vim.uri_from_fname(new_name),
            },
        },
    }
    -- log.debug("Sending workspace/willRenameFiles request", will_rename_params)
    local timeout_ms = 6000
    local success, resp = pcall(function()
        return client:request_sync(vim.lsp.protocol.Methods.workspace_willRenameFiles,
            will_rename_params, timeout_ms)
    end
    )
    -- log.debug("Got workspace/willRenameFiles response", resp)
    if not success then
        -- log.error("Error while sending workspace/willRenameFiles request", resp)
        return nil
    end
    if resp == nil or resp.result == nil then
        -- log.warn(
        -- "Got empty workspace/willRenameFiles response, maybe a timeout?")
        return nil
    end
    return resp.result
end

local get_regex = function(pattern)
    local regex = vim.fn.glob2regpat(pattern.glob)
    if pattern.options and pattern.options.ignorecase then
        return "\\c" .. regex
    end
    return regex
end

---@param filter {pattern: {matches?: "file" | "folder", glob: string, options?: {ignorecase: boolean}}}
---@param name string
---@param is_dir boolean
---@return boolean
local function match_filter(filter, name, is_dir)
    local pattern = filter.pattern
    local match_type = pattern.matches
    if not match_type or
    (match_type == "folder" and is_dir) or
    (match_type == "file" and not is_dir)
    then
        local regex = get_regex(pattern)
        local previous_ignorecase = vim.o.ignorecase
        vim.o.ignorecase = false
        local matched = vim.fn.match(name, regex) ~= -1
        vim.o.ignorecase = previous_ignorecase
        return matched
    end
    return false
end


-- needed for globs like `**/`
local ensure_dir_trailing_slash = function(path, is_dir)
    if is_dir and not path:match("/$") then
        return path .. "/"
    end
    return path
end

---@param name string
---@return string, boolean
local get_absolute_path = function(name)
    local absolute_path = vim.fs.abspath(name)
    local is_dir = not not vim.fn.isdirectory(absolute_path)
    return ensure_dir_trailing_slash(absolute_path, is_dir), is_dir
end

local function get_nested_path(table, keys)
    if #keys == 0 then
        return table
    end
    local key = keys[1]
    if table[key] == nil then
        return nil
    end
    return get_nested_path(table[key], { unpack(keys, 2) })
end

local function matches_file_operation_filters(filters, name)
    local absolute_path, is_dir = get_absolute_path(name)
    for _, filter in pairs(filters) do
        if match_filter(filter, absolute_path, is_dir) then
            return true
        end
    end
    return false
end

local M = {
    commands = {
        ---@param old_name string
        ---@param new_name string
        will_rename_file = function(old_name, new_name)
            for _, client in pairs(vim.lsp.get_clients()) do
                local will_rename = get_nested_path(
                    client,
                    {
                        "server_capabilities",
                        "workspace",
                        "fileOperations",
                        "willRename",
                    }
                )
                if will_rename ~= nil then
                    local filters = will_rename.filters or {}
                    if matches_file_operation_filters(filters, old_name) then
                        local edit = get_rename_file_workspace_edits(client, old_name,
                            new_name)
                        if edit ~= nil then
                            vim.lsp.util.apply_workspace_edit(edit,
                                client.offset_encoding)
                            vim.notify("applied workspace edit for file rename")
                        end
                    end
                end
            end
        end,
        ---@param old_name string
        ---@param new_name string
        did_rename_files = function(old_name, new_name)
            -- vim.notify("TODO did_rename_files", vim.log.levels.ERROR)
            for _, client in pairs(vim.lsp.get_clients()) do
                local did_rename =
                    get_nested_path(client,
                        {
                            "server_capabilities",
                            "workspace",
                            "fileOperations",
                            "didRename",
                        })
                if did_rename ~= nil then
                    local filters = did_rename.filters or {}
                    if matches_file_operation_filters(filters, old_name) then
                        local params = {
                            files = {
                                {
                                    oldUri = vim.uri_from_fname(old_name),
                                    newUri = vim.uri_from_fname(new_name),
                                },
                            },
                        }
                        client:notify(vim.lsp.protocol.Methods.workspace_didRenameFiles, params)
                    end
                end
            end
        end,
    },
}

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
