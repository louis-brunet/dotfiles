---@type vim.lsp.Config
return {
    ---@class LuaLanguageServerSettings
    settings = {
        --- https://luals.github.io/wiki/settings/
        ---@class LuaLanguageServerSettingsLua
        Lua = {
            telemetry = { enable = false },

            codelens = { enable = true },

            diagnostics = { enable = true },

            hint = {
                enable = true,

                --- assignment operations
                setType = true,

                --- Auto: Only show hint when there is more than 3 items or the table is mixed (indexes and keys)
                ---@type 'Enable' | 'Auto' | 'Disable'
                arrayIndex = "Disable",

                ---@type 'All' | 'Literal' | 'Disable'
                paramName = "Literal",
            },

            runtime = { version = "LuaJIT" },

            -- Make the server aware of Neovim runtime files
            workspace = {
                checkThirdParty = false,
                -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#lua_ls
                --
                library = {
                    vim.env.VIMRUNTIME,

                    -- Depending on the usage, you might want to add additional paths here.
                    -- E.g.: For using `vim.*` functions, add vim.env.VIMRUNTIME/lua.
                    -- "${3rd}/luv/library"
                    -- "${3rd}/busted/library",
                },
                --
                -- -- or pull in all of 'runtimepath'. NOTE: this is a lot slower:
                --
                -- library = vim.api.nvim_get_runtime_file("", true)
            },

            completion = { callSnippet = "Replace" },

            format = { defaultConfig = { indent_style = "space" } },
        },
    },
}
