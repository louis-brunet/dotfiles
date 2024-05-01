local M = {}

---@param predicate fun(qfitem: table):boolean
function M.filter_quickfix_list(predicate)
    local qflist = vim.fn.getqflist()
    local new_qflist = {}
    for _, qfitem in ipairs(qflist) do
        if predicate(qfitem) then
            table.insert(new_qflist, predicate)
        end
    end
    vim.fn.setqflist(new_qflist)
end

---@param index integer
function M.delete_quickfix_item(index)
    local qflist = vim.fn.getqflist()
    table.remove(qflist, index)
    vim.fn.setqflist(qflist)
end

---@param opts { confirm: boolean|nil }|nil
function M.delete_quickfix_current_line(opts)
    opts = opts or {}
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local function do_delete_qf_item()
        M.delete_quickfix_item(current_line)
        vim.notify('Deleted quickfix item', vim.log.levels.INFO, { title = 'delete_quickfix_current_line' })
    end

    if opts.confirm then
        local confirm = require('user.utils.ui').confirm
        local prompt = 'Delete quickfix item at line ' .. current_line .. '?'
        local callbacks = {
            on_accept = do_delete_qf_item,
        }
        confirm(prompt, callbacks)
    else
        do_delete_qf_item()
    end
end

---@param opts { confirm: boolean|nil }|nil
function M.delete_quickfix_visual(opts)
    opts = opts or {}
    -- TODO: delete_quickfix_visual
    error('TODO: delete_quickfix_visual')
end

return M
