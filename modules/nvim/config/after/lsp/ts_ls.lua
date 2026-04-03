local LSP_WORKSPACE_COMMANDS = {
    organize_imports = "_typescript.organizeImports",
    go_to_source_definition = "_typescript.goToSourceDefinition",
}

---@param bufnr integer|nil
---@return vim.lsp.Client|nil
local function get_typescript_lsp_client(bufnr)
    local clients = require("user.utils.lsp").get_buffer_lsp_clients({
        bufnr =
            bufnr,
    })

    for _, client in ipairs(clients) do
        if client.name == "ts_ls" or client.name == "tsserver" then
            return client
        end
    end

    vim.notify("[get_typescript_lsp_client] no active tsserver found",
        vim.log.levels.WARN)

    return nil
end

local typescript_commands = {
    ---@param opts { bufnr: integer|nil, client: vim.lsp.Client|nil, delete_unused: boolean|nil }|nil
    organize_imports = function(opts)
        opts = opts or {}
        local bufnr = opts.bufnr or 0
        local skipDestructiveCodeActions = not opts.delete_unused

        local client = opts.client or get_typescript_lsp_client(bufnr)
        if not client then
            vim.notify("ts LSP client not found for buffer " .. bufnr,
                vim.log.levels.WARN,
                { title = LSP_WORKSPACE_COMMANDS.organize_imports })
            return false
        end

        local execute_command_params = {
            command = LSP_WORKSPACE_COMMANDS.organize_imports,
            arguments = {
                vim.api.nvim_buf_get_name(bufnr),
                { skipDestructiveCodeActions = skipDestructiveCodeActions },  -- delete unused imports
            },
        }

        local function execute_command_callback(...)
            vim.notify("imports organized", vim.log.levels.INFO,
                { title = LSP_WORKSPACE_COMMANDS.organize_imports })
        end

        client:request(vim.lsp.protocol.Methods.workspace_executeCommand,
            execute_command_params, execute_command_callback)
        return true
    end,

    -- _typescript.goToSourceDefinition integration
    ---@param opts { client: vim.lsp.Client|nil, winnr: integer|nil, use_fallback: boolean|nil }|nil
    go_to_source_definition = function(opts)
        opts = opts or {}
        if opts.winnr == nil then
            opts.winnr = vim.api.nvim_get_current_win()
        end
        if opts.use_fallback == nil then
            opts.use_fallback = true
        end
        local bufnr = vim.api.nvim_win_get_buf(opts.winnr)

        local client = opts.client or get_typescript_lsp_client()
        if not client then
            vim.notify("ts LSP client not found", vim.log.levels.WARN,
                { title = LSP_WORKSPACE_COMMANDS.go_to_source_definition })
            return false
        end

        local positional_params = vim.lsp.util.make_position_params(opts.winnr,
            client.offset_encoding)
        local execute_command_params = {
            command = LSP_WORKSPACE_COMMANDS.go_to_source_definition,
            arguments = {
                positional_params.textDocument.uri,
                positional_params.position,
            },
        }
        local function execute_callback(...)
            local args = { ... }
            local handler = client.handlers
                [vim.lsp.protocol.Methods.textDocument_definition] or
                vim.lsp.handlers
                [vim.lsp.protocol.Methods.textDocument_definition]
            if not handler then
                vim.notify(
                    "failed to go to source definition: could not resolve definition handler",
                    vim.log.levels.ERROR,
                    { title = LSP_WORKSPACE_COMMANDS.go_to_source_definition })
                return
            end

            local res = args[2] or ({})
            if vim.tbl_isempty(res) then
                if opts.use_fallback == true then
                    return client:request(
                        vim.lsp.protocol.Methods.textDocument_definition,
                        positional_params, handler, bufnr)
                end
                vim.notify(
                    "failed to go to source definition: no source definitions found",
                    vim.log.levels.WARN,
                    { title = LSP_WORKSPACE_COMMANDS.go_to_source_definition })
                return
            end

            handler(unpack(args))
        end

        client:request(vim.lsp.protocol.Methods.workspace_executeCommand,
            execute_command_params, execute_callback)
        -- client.request(LSP_METHODS.execute_command, execute_command_params,
        --     execute_callback)
        return true
    end,
}

---@type vim.lsp.Config
return {
    -- filetypes = {
    --     'angular.html',
    --     -- defaults
    --     'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx'
    -- },

    -- maps to lspconfig's `init_options` (!= `settings`)
    init_options = {
        hostInfo = "neovim",
        preferences = {
            quotePreference = "single",

            includeInlayParameterNameHints = "literals",  -- 'none' | 'literals' | 'all';
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,

            importModuleSpecifierPreference = "relative",
            importModuleSpecifierEnding = "minimal",
        },
    },

    -- NOTE: deprecated
    -- -- maps to lspconfig's `commands` option
    -- commands = {
    --     TypescriptOrganizeImports = {
    --         typescript_commands.organize_imports,
    --         description = "Organize imports"
    --     },
    --     -- _typescript.goToSourceDefinition integration
    --     TypescriptGoToSourceDefinition = {
    --         typescript_commands.go_to_source_definition,
    --         description = "Go to source definition"
    --     }
    -- },

    settings = {
        settings = {
            typescript = {
                -- format = {
                --     indentSize = vim.o.shiftwidth,
                --     convertTabsToSpaces = vim.o.expandtab,
                --     tabSize = vim.o.tabstop,
                -- },
            },
            javascript = {
                -- format = {
                --     indentSize = vim.o.shiftwidth,
                --     convertTabsToSpaces = vim.o.expandtab,
                --     tabSize = vim.o.tabstop,
                -- },
            },
            completions = { completeFunctionCalls = true },
        },
    },

    on_attach = function(client, bufnr)
        ---@class UserTypescriptCommand
        ---@field command_name string
        ---@field keymap string|nil
        ---@field action string|function
        ---@field description string|nil

        ---@type UserTypescriptCommand[]
        local ts_commands = {
            {
                command_name = "TypescriptOrganizeImports",
                action = function()
                    typescript_commands.organize_imports({
                        bufnr = bufnr,
                        delete_unused = true,
                    })
                end,
                description = "Organize imports",
            },
            {
                command_name = "TypescriptGoToSourceDefinition",
                keymap = "gs",
                action = function()
                    typescript_commands.go_to_source_definition({
                        client =
                            client,
                        use_fallback = true,
                    })
                end,
                description = "Go to source definition",
            },
        }

        for _, command in ipairs(ts_commands) do
            local desc = nil
            if command.description then
                desc = "typescript: " .. command.description
            end

            vim.api.nvim_buf_create_user_command(
                bufnr,
                command.command_name,
                command.action,
                { desc = desc }
            )

            if command.keymap then
                vim.keymap.set(
                    "n",
                    command.keymap,
                    command.action,
                    { buffer = bufnr, desc = desc }
                )
            end
        end

        vim.api.nvim_buf_create_user_command(
            bufnr,
            "Typescript",
            function()
                local select_items = {}
                local desc_to_item = {}

                for _, cmd in pairs(ts_commands) do
                    table.insert(select_items, cmd.description)
                    desc_to_item[cmd.description] = cmd
                end

                -- TODO: handle selection and non selection
                vim.ui.select(
                    select_items,
                    {},
                    function(selected)
                        if not selected then
                            vim.notify("no selection", vim.log.levels.DEBUG)
                            return
                        end

                        local selected_item = desc_to_item[selected]
                        selected_item.action()
                    end
                )
            end,
            { desc = "typescript: select action" }
        )

        -- vim.api.nvim_buf_create_user_command(
        --     bufnr,
        --     'Typescript',
        --     function()
        --         local choices = {
        --         }
        --
        --         vim.ui.select(vim.tbl_keys(choices), {}, function() end)
        --     end,
        --     { desc = 'typescript: Organize imports' }
        -- )
    end,
}
