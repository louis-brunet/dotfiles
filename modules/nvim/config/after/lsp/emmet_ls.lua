---@type vim.lsp.Config
return {
    -- https://github.com/emmetio/emmet/blob/master/src/config.ts#L79-L267
    init_options = {
        html = {
            options = {
                -- ["bem.enabled"] = true,
            },
        },
        jsx = {
            options = {
                ['jsx.enabled'] = true,
            },
        },
    },
    -- filetypes = {
    --
    -- },
}
