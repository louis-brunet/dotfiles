---@type LazySpec
return {
    -- Automatically install LSPs to stdpath for neovim
    {
        'mason-org/mason.nvim',
        -- cmd = 'Mason',
        config = true,
    },

    'mason-org/mason-lspconfig.nvim',
}
