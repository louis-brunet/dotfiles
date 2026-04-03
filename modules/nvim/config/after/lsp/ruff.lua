---@type vim.lsp.Config
return {
    -- init_options = {
    --     settings = {
    --         -- Ruff language server settings go here
    --     }
    -- },
    on_attach = function(client, _)
        -- Disable hover in favor of Pyright
        client.server_capabilities.hoverProvider = false
    end,
}
