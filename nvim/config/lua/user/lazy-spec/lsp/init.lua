-- [[ Configure LSP ]]
---@type LazySpec
local M = {
    {
        'dmmulroy/tsc.nvim',
        cmd = { 'TSC', 'TSCOpen' },
        opts = {
            -- auto_open_qflist = true,
            -- auto_close_qflist = false,
            -- auto_focus_qflist = false,
            -- auto_start_watch_mode = false,
            use_trouble_qflist = true,
            -- run_as_monorepo = false,
            -- bin_path = utils.find_tsc_bin(),
            -- enable_progress_notifications = true,
            -- flags = {
            --     noEmit = true,
            --     project = function()
            --         return utils.find_nearest_tsconfig()
            --     end,
            --     watch = false,
            -- },
            -- hide_progress_notifications_from_history = true,
            -- spinner = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
            -- pretty_errors = true,
        },

        dependencies = {
            "folke/trouble.nvim",
            dependencies = { "nvim-tree/nvim-web-devicons" },
            opts = {
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            },
        }
    },
    {
        -- LSP Configuration & Plugins
        'neovim/nvim-lspconfig',
        event = 'BufReadPre',
        dependencies = {
            -- Automatically install LSPs to stdpath for neovim
            { 'williamboman/mason.nvim', config = true },
            'williamboman/mason-lspconfig.nvim',

            -- Useful status updates for LSP
            { 'j-hui/fidget.nvim',       tag = 'legacy',                              opts = {} },

            -- Additional lua configuration, makes nvim stuff amazing!
            'folke/neodev.nvim',

            -- LSP dependencies in lua/user/plugins/lsp/*.lua (except init.lua)
            { import = 'user.lazy-spec.lsp' },
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
                    local server_config = servers[server_name] or {}

                    local server_cmd = server_config.cmd
                    server_config.cmd = nil

                    local server_commands = server_config.commands
                    server_config.commands = nil

                    local server_filetypes = server_config.filetypes
                    server_config.filetypes = nil

                    local server_init_options = server_config.init_options
                    server_config.init_options = nil


                    -- :h lspconfig-setup
                    require('lspconfig')[server_name].setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        settings = server_config,
                        filetypes = server_filetypes,
                        init_options = server_init_options,
                        commands = server_commands,
                        -- root_dir = function(filename, bufnr) end, -- :h lspconfig-root-detection
                        -- single_file_support = nil,
                        -- autostart = true,
                        cmd = server_cmd,
                        -- handlers = {},
                        -- on_new_config = function (new_config, new_root_dir) end,
                    }
                end,
            }
        end
    },
}

return M
