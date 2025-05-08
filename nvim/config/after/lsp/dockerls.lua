---@type vim.lsp.Config
return {
    -- https://github.com/rcjsuen/dockerfile-language-server?tab=readme-ov-file#language-server-settings
    settings = {
        docker = { languageserver = { diagnostics = {}, formatter = {} } },
    },
}
