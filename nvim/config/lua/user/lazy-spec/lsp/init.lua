-- [[ Configure LSP ]]
---@type LazySpec
local M = {
    {
        "dmmulroy/tsc.nvim",
        cmd = { "TSC", "TSCOpen" },
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
        },
    },
    {
        -- LSP Configuration & Plugins
        "neovim/nvim-lspconfig",
        event = "BufReadPre",
        dependencies = {
            -- Useful status updates for LSP
            { "j-hui/fidget.nvim",          opts = {} },

            -- LSP dependencies in lua/user/lazy-spec/lsp/*.lua (except init.lua)
            { import = "user.lazy-spec.lsp" },
        },
        config = function(_, _)
            -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require("cmp_nvim_lsp").default_capabilities(
                capabilities)

            -- Ensure the servers above are installed
            local mason_lspconfig = require("mason-lspconfig")

            local user_config = require("user.config.lsp")
            local common_on_attach = user_config.on_attach

            mason_lspconfig.setup({
                automatic_enable = false,                          -- this is done manually with vim.lsp.enable(server_name)
                ensure_installed = user_config.servers_to_enable,  -- install the servers that will be enabled
            })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("user.lsp.common_on_attach",
                    {}),
                callback = function(args)
                    local client_id = args.data.client_id
                    local client = assert(vim.lsp.get_client_by_id(client_id))
                    common_on_attach(client, args.buf)
                end,
            })

            -- common config applied to all servers by default
            -- Server-specific configs can go in
            -- `<config_root>/after/lsp/<server_name>.lua`
            ---@type vim.lsp.Config
            local common_config = { capabilities = capabilities }
            vim.lsp.config("*", common_config)

            vim.lsp.enable(user_config.servers_to_enable)
        end,
    },
}

return M
