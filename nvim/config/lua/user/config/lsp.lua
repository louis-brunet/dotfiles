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

local function get_user_cache_dir()
    local cache_home = vim.env.XDG_CACHE_HOME
    if not cache_home or cache_home == "" then
        cache_home = vim.fs.joinpath(vim.fn.expand("~"), ".cache")
    end
    return cache_home
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

---@class UserLspConfig
local M = {}

---@type { [string]: UserLspServerConfig }
M.lspconfig_servers = {
    -- clangd = {},
    -- gopls = {},

    pyright = {
        settings = {
            python = {
                -- venv = '.venv'
                -- venvPath = '~/.pyenv/versions'
            },
        },
    },
    ruff = {
        -- init_options = {
        --     settings = {
        --         -- Ruff language server settings go here
        --     }
        -- },
        on_attach = function(client, _)
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
        end,
    },

    ts_ls = {
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
    },

    html = { filetypes = { "angular.html", "handlebars", "html", "templ" } },
    tailwindcss = {
        filetypes = { "html", "css", "tsx", "angular.html" },  --, 'javascript', 'typescript', 'tsx', 'pug'},
        tailwindCSS = {
            emmetCompletions = true,
            -- includeLanguages = {
            --     pug = 'html',
            --     -- plaintext = 'html',
            -- },
        },
    },

    rust_analyzer = {

        -- maps to lspconfig's `cmd` option
        -- cmd = { '/home/louis/.cargo/bin/rust-analyzer' },

        settings = {
            ["rust-analyzer"] = {
                diagnostics = {
                    enable = true,
                    -- experimental = { enable = true },
                },
                cargo = {
                    features = "all",
                    buildScripts = { enable = true },
                    -- allFeatures = true,
                    -- loadOutDirsFromCheck = true,
                    -- runBuildScripts = true,
                },
                -- Add clippy lints for Rust.
                -- checkOnSave = {
                --     allFeatures = true,
                --     command = "clippy",
                --     extraArgs = { "--no-deps" }, --, "-A", "clippy::needless_return" },
                -- },
                checkOnSave = true,
                procMacro = {
                    enable = true,
                    ignored = {
                        ["async-trait"] = { "async_trait" },
                        ["napi-derive"] = { "napi" },
                        ["async-recursion"] = { "async_recursion" },
                    },
                },
                check = {
                    command = "clippy",
                    extraArgs = { "--no-deps" },
                    -- overrideCommand = { "cargo", "clippy", "--workspace", "--message-format=json", "--all-targets", "--",
                    --     "-A", "clippy::needless_return", },
                },
            },
        },
    },

    -- gopls = {
    --     gopls = { -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
    --         templateExtensions = { 'tmpl', 'gotmpl' },
    --         analyses = {
    --             unusedparams = true,
    --         },
    --     },
    --     filetypes = {
    --         'template',
    --         -- default filtetypes
    --         'go', 'gomod', 'gowork', 'gotmpl',
    --     },
    -- },

    lua_ls = {
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
    },

    -- NOTE: also run `:MasonInstall shellcheck` and `:MasonInstall shfmt` for
    -- more features
    bashls = {
        filetypes = {
            "zsh",
            "bash",

            -- default filetypes
            "sh",
        },
    },

    jsonls = {
        settings = {
            json = {
                validate = { enable = true },
                schemas = {
                    {
                        fileMatch = "package.json",
                        url = "https://json.schemastore.org/package.json",
                    },
                    {
                        fileMatch = { "tsconfig.json", "tsconfig.*.json" },
                        url = "https://json.schemastore.org/tsconfig",
                    },
                    {
                        fileMatch = "pyrightconfig.json",
                        url =
                        "https://raw.githubusercontent.com/microsoft/pyright/main/packages/vscode-pyright/schemas/pyrightconfig.schema.json",
                    },
                    -- {
                    --     fileMatch = "nest-cli.json",
                    --     url = "https://json.schemastore.org/nest-cli"
                    -- },
                },
            },
        },
    },

    -- docker_compose_language_service = {
    --     -- default is 'yaml.docker-compose'
    --     -- filetypes = { 'yaml.docker-compose' },
    -- },

    dockerls = {
        -- https://github.com/rcjsuen/dockerfile-language-server?tab=readme-ov-file#language-server-settings
        settings = {
            docker = { languageserver = { diagnostics = {}, formatter = {} } },
        },
    },

    angularls = {
        filetypes = {
            "angular.html",
            -- defaults
            "typescript",
            "html",
            "typescriptreact",
            "typescript.tsx",
        },
    },


    yamlls = {
        on_attach = function(client, _)
            client.server_capabilities.documentFormattingProvider = true
        end,
        -- https://github.com/redhat-developer/yaml-language-server?tab=readme-ov-file#language-server-settings
        settings = {
            redhat = { telemetry = { enabled = false } },
            yaml = {
                schemas = {
                    -- ["https://json.schemastore.org/github-workflow.json"] = {
                    --     ".github/workflows/*.{yaml,yml}",
                    -- },
                    -- ["https://json.schemastore.org/github-action.json"] = {
                    --     ".github/actions/*.{yaml,yml}",
                    --     "action.{yaml,yml}"
                    -- },
                    ["https://raw.githubusercontent.com/canonical/cloud-init/refs/heads/main/cloudinit/config/schemas/schema-cloud-config-v1.json"] =
                    "*cloud-config.{yaml,yml}",
                },
                format = { enable = true, singleQuote = true, printWidth = 80 },
            },
        },
    },

    terraformls = {
        init_options = { experimentalFeatures = { prefillRequiredFields = true } },
    },

    eslint = {
        settings = {
            eslint = {
                runtime = "node",

                -- FIXME: seems to not work like I thought (like NODE_OPTIONS=--max_old_space_size=4096) -- for big files
                execArgv = { "--max_old_space_size=4096" },
            },
        },
    },

    -- https://writewithharper.com/docs/integrations/neovim
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#harper_ls
    harper_ls = {
        settings = {
            ["harper-ls"] = {
                -- userDictPath = vim.fs.joinpath(
                --     vim.fn.expand("$XDG_CONFIG_HOME"),
                --     "harper-ls"
                -- ),
                -- fileDictPath = vim.fs.joinpath(
                --     vim.fn.expand("$XDG_DATA_HOME"),
                --     "harper-ls",
                --     "file_dictionaries"
                -- ),
                linters = {
                    -- https://writewithharper.com/docs/rules
                    SpellCheck = false,
                    SpelledNumbers = false,
                    AnA = true,
                    SentenceCapitalization = false,
                    UnclosedQuotes = true,
                    WrongQuotes = false,
                    LongSentences = false,
                    RepeatedWords = true,
                    Spaces = true,
                    Matcher = true,
                    CorrectNumberSuffix = true,
                    ToDoHyphen = false,
                },
                codeActions = { ForceStable = false },
                markdown = { IgnoreLinkTitle = false },
                diagnosticSeverity = "hint",  -- Can also be "information", "warning", or "error"
                isolateEnglish = false,
            },
        },
    },

    lemminx = {
        settings = {
            -- https://github.com/eclipse-lemminx/lemminx/blob/main/docs/Configuration.md#settings
            -- NOTE: Additional settings mentioned here:
            --   - coc-xml: https://github.com/fannheyward/coc-xml?tab=readme-ov-file#supported-settings
            --   - vscode-xml: https://github.com/redhat-developer/vscode-xml?tab=readme-ov-file#supported-vs-code-settings
            xml = {
                -- https://github.com/redhat-developer/vscode-xml/blob/main/docs/Formatting.md
                format = {
                    enabled = true,
                    -- preserve, splitNewLine, alignWithFirstAttr
                    splitAttributes = "splitNewLine",
                    splitAttributesIndentSize = 2,
                    spaceBeforeEmptyCloseTag = true,
                    preserveAttributeLineBreaks = true,  -- can be overriden by splitAttributes
                    closingBracketNewLine = false,
                    maxLineWidth = 80,
                },
                logs = {
                    client = true,
                    -- file = ...
                },
                fileAssociations = {
                    -- {
                    --     systemId =
                    --     "https://raw.githubusercontent.com/apigee/api-platform-samples/refs/heads/master/schemas/policy/assign_message.xsd",
                    --     pattern = "AM-*.xml",
                    -- }
                    -- example:
                    -- {
                    --     systemId =
                    --     "C:\\org.eclipse.lsp4xml\\src\\test\\resources\\xsd\\projectDescription.xsd",
                    --     pattern = ".project",
                    -- }
                },
                --
                server = {
                    workDir = vim.fs.joinpath(get_user_cache_dir(), "lemminx"),
                    -- FIXME: cannot download schemas because of Netskope
                    -- proxy's self-signed cert, not recognized by
                    -- Java/by the compiled lemminx binary.
                    -- Should probably try to install JRE and lemminx externally
                    -- to fix these issues
                    --
                    -- binary = { args = "-Djava.net.useSystemProxies=true" },
                    -- binary = { args = "-Djavax.net.ssl.trustStore='/Library/Application Support/Netskope/STAgent/data/nscacert.pem'" },
                    -- vmargs = '-Djava.net.useSystemProxies=true',
                    -- vmargs = '-Dhttp.proxyHost=gateway-par1.goskope.com',
                    -- vmargs = "-Djavax.net.ssl.trustStore='/Library/Application Support/Netskope/STAgent/data/nscacert.pem'",
                },
            },
        },
    },
}

---@param client vim.lsp.Client
---@param bufnr integer
function M.on_attach(client, bufnr)
    ---@param modes string[]|string
    ---@param keys string
    ---@param func function|string
    ---@param desc string
    local map = function(modes, keys, func, desc)
        if desc then
            desc = "LSP: " .. desc
        end

        vim.keymap.set(modes, keys, func, { buffer = bufnr, desc = desc })
    end

    ---@param keys string
    ---@param func function|string
    ---@param desc string
    local nmap = function(keys, func, desc)
        map("n", keys, func, desc)
    end

    ---@param keys string
    ---@param func function|string
    ---@param desc string
    local imap = function(keys, func, desc)
        map("i", keys, func, desc)
    end

    nmap("<leader>rn", vim.lsp.buf.rename, "[r]e[n]ame")
    nmap("<leader>ca", vim.lsp.buf.code_action, "[c]ode [a]ction")
    nmap("<A-Enter>", vim.lsp.buf.code_action, "code action")

    local telescope_lsp_options = {
        layout_strategy = "vertical",
        -- layout_config = {
        -- },
        fname_width = 70,
    }

    nmap("gd",
        function()
            require("telescope.builtin").lsp_definitions(
                telescope_lsp_options)
        end, "[G]oto [D]efinition")
    nmap("gr",
        function()
            require("telescope.builtin").lsp_references(
                telescope_lsp_options)
        end, "[G]oto [R]eferences")
    nmap("gI",
        function()
            require("telescope.builtin").lsp_implementations(
                telescope_lsp_options)
        end,
        "[G]oto [I]mplementation")
    nmap("<leader>D",
        function()
            require("telescope.builtin").lsp_type_definitions(
                telescope_lsp_options)
        end,
        "Type [D]efinition")
    nmap("<leader>ds",
        function()
            require("telescope.builtin").lsp_document_symbols(
                telescope_lsp_options)
        end,
        "[D]ocument [S]ymbols")
    nmap("<leader>ws",
        function()
            require("telescope.builtin").lsp_dynamic_workspace_symbols(
                telescope_lsp_options)
        end,
        "[W]orkspace [S]ymbols")

    -- See `:help K` for why this keymap
    nmap("K", vim.lsp.buf.hover, "Hover Documentation")
    nmap("<C-s>", vim.lsp.buf.signature_help, "[S]ignature Documentation")
    imap("<C-s>", vim.lsp.buf.signature_help, "[S]ignature Documentation")

    -- Lesser used LSP functionality
    nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    nmap("<leader>wa", vim.lsp.buf.add_workspace_folder,
        "[W]orkspace [A]dd Folder")
    nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder,
        "[W]orkspace [R]emove Folder")
    nmap("<leader>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "[W]orkspace [L]ist Folders")

    -- Create a command `:Format` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
        local function log_debug(message)
            vim.notify(message, vim.log.levels.DEBUG, { title = ":Format" })
        end

        local clients_to_ignore = {}
        local lsp_utils = require("user.utils.lsp")
        local attached_clients = lsp_utils.get_buffer_lsp_clients({
            bufnr = bufnr,
            method = vim.lsp.protocol.Methods.textDocument_formatting,
        })
        local should_ignore_ts_ls = lsp_utils.contains_any_client(
            -- TODO: do the same thing with angularls?
                attached_clients, { "eslint" }) and
            lsp_utils.contains_any_client(attached_clients,
                { "ts_ls", "tsserver" })
        if should_ignore_ts_ls then
            for _, ts_ls_name in ipairs({ "ts_ls", "tsserver" }) do
                table.insert(clients_to_ignore, ts_ls_name)
            end
        end

        if #clients_to_ignore then
            log_debug("Ignoring clients " .. vim.inspect(clients_to_ignore))
        end

        -- vim.tbl_contains(attached_clients, '')
        vim.lsp.buf.format({
            filter = function(format_client)
                return not vim.tbl_contains(clients_to_ignore, format_client
                    .name)
            end,
        })
    end, { desc = "Format current buffer with LSP" })

    -- Create an autocommand to highlight hovered word using attached LSP
    local highlight_augroup_name = "LspDocumentHighlightGroup"
    local highlight_augroup = vim.api.nvim_create_augroup(highlight_augroup_name,
        { clear = true })
    local highlight_augroup_opts = function(callback)
        return { callback = callback, group = highlight_augroup, buffer = bufnr }
    end
    if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
        vim.api.nvim_create_autocmd("CursorHold",
            highlight_augroup_opts(vim.lsp.buf.document_highlight))
        vim.api.nvim_create_autocmd("CursorHoldI",
            highlight_augroup_opts(vim.lsp.buf.document_highlight))
        vim.api.nvim_create_autocmd("CursorMoved",
            highlight_augroup_opts(vim.lsp.buf.clear_references))
        vim.api.nvim_create_autocmd("CursorMovedI",
            highlight_augroup_opts(vim.lsp.buf.clear_references))
    end

    -- Enable inlay hints
    if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
        if vim.lsp.inlay_hint and type(vim.lsp.inlay_hint.enable) == "function" then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
        nmap("<leader>li", function()
            local is_enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
            vim.lsp.inlay_hint.enable(not is_enabled, { bufnr = bufnr })
        end, "toggle [i]nlay hints")
    end

    nmap("<leader>lt", function()
        ---@type vim.diagnostic.Filter
        local diagnostic_filter = { bufnr = 0 }
        local was_enabled = vim.diagnostic.is_enabled(diagnostic_filter)
        vim.diagnostic.enable(not was_enabled, diagnostic_filter)

        local message = " diagnostics"
        if was_enabled then
            message = "Disabled " .. message
        else
            message = "Enabled " .. message
        end
        vim.notify(message)
    end, "[t]oggle diagnostics")
end

return M
