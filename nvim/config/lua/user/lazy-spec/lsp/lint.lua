---@type LazySpec
return {
    'mfussenegger/nvim-lint',
    ft = 'dockerfile',  -- only load when opening a Dockerfile
    config = function()
        local lint = require('lint')

        lint.linters_by_ft = {
            -- NOTE: hadolint is installed with mason, see ./mason.lua
            dockerfile = { 'hadolint' },
        }

        -- trigger linting on these events
        vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
            callback = function()
                lint.try_lint()
            end,
        })
    end,
}
