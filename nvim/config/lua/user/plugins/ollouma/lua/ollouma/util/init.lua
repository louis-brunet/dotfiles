local M = {}

function M.is_function(value)
    return not not value and type(value) == 'function'
end

return M
