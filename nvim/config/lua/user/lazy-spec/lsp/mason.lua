---@type LazySpec
return {
    -- Automatically install LSPs to stdpath for neovim
    {
        'mason-org/mason.nvim',
        cmd = 'Mason',
        config = true,
    },

    'mason-org/mason-lspconfig.nvim',

    -- Install extra tools from mason registry
    {
        'mason-org/mason.nvim',
        opts_extend = { 'ensure_installed' },
        opts = {
            ensure_installed = { 'hadolint' },
        },
        config = function(_, opts)
            require('mason').setup(opts)
            local registry = require('mason-registry')
            registry.refresh(function()
                for _, name in ipairs(opts.ensure_installed) do
                    local pkg = registry.get_package(name)
                    if not pkg:is_installed() then
                        pkg:install()
                    end
                end
            end)
        end,
    },
}
