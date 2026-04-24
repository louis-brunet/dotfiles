---@type vim.lsp.Config
return {
    ---@type lspconfig.settings.eslint
    settings = {
        eslint = {
            runtime = "node",

            -- codeAction = {
            --     disableRuleComment = true,
            --     showDocumentation = true,
            -- },

            -- FIXME: seems to not work like I thought (like NODE_OPTIONS=--max_old_space_size=4096) -- for big files
            execArgv = { "--max_old_space_size=4096" },
        },
    },
}
