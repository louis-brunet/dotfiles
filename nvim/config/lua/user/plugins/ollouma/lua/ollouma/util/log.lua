local function log(vim_level, ...)
    vim.notify('[ollouma]: ' .. vim.fn.join({ ... }, ' '), vim_level)
end

local M = {}

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
