-- [[ Configure LSP ]]
---@type LazySpec
local M = {
    {
        -- LSP Configuration & Plugins
        'neovim/nvim-lspconfig',
        -- FIXME: this make `:e` necessary when entering nvim to edit a files
        -- rather than a directory (i.e. `nvim some/file` rather than `nvim .`
        event = 'VeryLazy',
        dependencies = {
            -- Automatically install LSPs to stdpath for neovim
            { 'williamboman/mason.nvim', config = true },
            'williamboman/mason-lspconfig.nvim',

            -- Useful status updates for LSP
            { 'j-hui/fidget.nvim',       tag = 'legacy', opts = {} },

            -- Additional lua configuration, makes nvim stuff amazing!
            'folke/neodev.nvim',

            -- LSP dependencies in lua/user/plugins/lsp/*.lua (except init.lua)
            { import = 'user.plugins.lsp' },
        },
        config = function(_, _)
            -- Setup neovim lua configuration
            require('neodev').setup()

            -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            -- Ensure the servers above are installed
            local mason_lspconfig = require 'mason-lspconfig'

            local user_config = require('user.config.lsp')
            local servers = user_config.servers
            local on_attach = user_config.on_attach

            mason_lspconfig.setup {
                ensure_installed = vim.tbl_keys(servers),
            }

            mason_lspconfig.setup_handlers {
                function(server_name)
                    require('lspconfig')[server_name].setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        settings = servers[server_name],
                        filetypes = (servers[server_name] or {}).filetypes,
                        init_options = (servers[server_name] or {}).init_options,
                    }
                end,
            }
        end
    },

}

return M
