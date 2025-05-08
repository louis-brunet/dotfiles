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
            { "j-hui/fidget.nvim",          tag = "legacy", opts = {} },

            -- LSP dependencies in lua/user/lazy-spec/lsp/*.lua (except init.lua)
            { import = "user.lazy-spec.lsp" },
        },
        config = function(_, _)
            ---@class UserLspServerConfig
            ---@field cmd string[]|nil
            ---@field filetypes string[]|nil
            ---@field init_options table<string, string|table|boolean>|nil
            ---@field on_attach nil|fun(client: vim.lsp.Client, bufnr: integer):nil
            ---@field settings table<string, string|table|boolean>|nil

            -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require("cmp_nvim_lsp").default_capabilities(
                capabilities)

            -- Ensure the servers above are installed
            local mason_lspconfig = require("mason-lspconfig")

            local user_config = require("user.config.lsp")
            local servers = user_config.lspconfig_servers
            local common_on_attach = user_config.on_attach

            mason_lspconfig.setup({
                automatic_enable = false, -- this is done manually with vim.lsp.enable(server_name)
                ensure_installed = vim.tbl_keys(servers),
            })

            vim.lsp.config(
                "*",
                ---@type vim.lsp.ClientConfig
                { capabilities = capabilities, }
            )

            for server_name, server_config in pairs(servers) do
                ---@type (fun(client: vim.lsp.Client, bufnr: integer): nil)[]
                local server_on_attach = {
                    common_on_attach,
                }
                if type(server_config.on_attach) == "function" then
                    table.insert(server_on_attach, server_config.on_attach)
                end

                ---@type vim.lsp.Config
                local client_config = {
                    on_attach = server_on_attach,
                    settings = server_config.settings,
                    filetypes = server_config.filetypes,
                    init_options = server_config.init_options,
                    -- workspace_required = false,
                    -- root_markers =
                    -- root_dir = function(filename, bufnr) end,
                    -- autostart = true,
                    cmd = server_config.cmd,
                    -- handlers = {},
                    -- on_new_config = function (new_config, new_root_dir) end,
                }
                vim.lsp.config(server_name, client_config)
                vim.lsp.enable(server_name, true)
            end
        end,
    },
}

return M
