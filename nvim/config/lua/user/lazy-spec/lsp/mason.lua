---@type LazySpec
return {
    -- Automatically install LSPs to stdpath for neovim
    {
        'williamboman/mason.nvim',
        cmd = 'Mason',
        config = true,
    },

    'williamboman/mason-lspconfig.nvim',
}
