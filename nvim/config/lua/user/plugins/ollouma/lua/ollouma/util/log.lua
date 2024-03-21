local M = {
    --- :h vim.log.levels
    level = vim.log.levels.INFO
}

local function log(vim_level, ...)
    if M.level > vim_level then
        return
    end

    vim.notify('[ollouma]: ' .. vim.fn.join({ ... }, ' '), vim_level)
end

function M.error(...)
    log(vim.log.levels.ERROR, ...)
end

function M.warn(...)
    log(vim.log.levels.WARN, ...)
end

function M.info(...)
    log(vim.log.levels.INFO, ...)
end

function M.debug(...)
    log(vim.log.levels.DEBUG, ...)
end

function M.trace(...)
    log(vim.log.levels.TRACE, ...)
end

return M
