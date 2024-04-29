---@param bufnr integer|nil
---@return vim.lsp.Client|nil
local function get_typescript_lsp_client(bufnr)
    if bufnr == nil then
        bufnr = vim.api.nvim_get_current_buf()
    end

    local client_filter = { bufnr = bufnr }
    local clients = {}
    if type(vim.lsp.get_clients) == 'function' then
        clients = vim.lsp.get_clients(client_filter)
    else
        clients = vim.lsp.get_active_clients(client_filter)
    end

    ---@cast clients vim.lsp.Client[]

    for _, client in ipairs(clients) do
        if client.name == 'tsserver' then
            return client
        end
    end

    vim.notify('[get_typescript_lsp_client] no active tsserver found', vim.log.levels.WARN)

    return nil
end


local LSP_METHODS = {
    execute_command = 'workspace/executeCommand',
    definition = 'textDocument/definition'
}
local LSP_WORKSPACE_COMMANDS = {
    organize_imports = '_typescript.organizeImports',
    go_to_source_definition = '_typescript.goToSourceDefinition',
}

local typescript_commands = {
    ---@param bufnr integer|nil
    organize_imports = function(bufnr)
        if bufnr == nil then
            bufnr = 0
        end

        local params = {
            command = LSP_WORKSPACE_COMMANDS.organize_imports,
            arguments = {
                vim.api.nvim_buf_get_name(bufnr),       -- organize for current buffer
                { skipDestructiveCodeActions = false }, -- delete unused imports
            },
            title = ""
        }
        vim.lsp.buf.execute_command(params)
    end,

    -- TODO: _typescript.goToSourceDefinition integration
    ---@param opts { winnr: integer|nil, use_fallback: boolean|nil}|nil
    go_to_source_definition = function(opts)
        opts = opts or {}
        if opts.winnr == nil then
            opts.winnr = vim.api.nvim_get_current_win()
        end
        if opts.use_fallback == nil then
            opts.use_fallback = true
        end
        local bufnr = vim.api.nvim_win_get_buf(opts.winnr)

        local client = get_typescript_lsp_client()
        if not client then
            vim.notify('[go_to_source_definition] ts LSP client not found', vim.log.levels.WARN)
            return false
        end

        local positional_params = vim.lsp.util.make_position_params(opts.winnr, client.offset_encoding)
        -- vim.notify('TODO: integrate _typescript.goToSourceDefinition', vim.log.levels.ERROR)
        -- error('TODO')

        local execute_command_params = {
            command = LSP_WORKSPACE_COMMANDS.go_to_source_definition,
            arguments = {
                positional_params.textDocument.uri,
                positional_params.position,
            },
        }
        local function execute_callback(...)
            local args = {...}
            local handler = client.handlers[LSP_METHODS.definition] or vim.lsp.handlers[LSP_METHODS.definition]
            if not handler then
                print("[go_to_source_definition] failed to go to source definition: could not resolve definition handler")
                return
            end

            local res = args[2] or ({})
            if vim.tbl_isempty(res) then
                if opts.use_fallback == true then
                    return client.request(LSP_METHODS.definition, positional_params, handler, bufnr)
                end
                print("[go_to_source_definition] failed to go to source definition: no source definitions found")
                return
            end
            handler(unpack(args))
        end

        client.request('workspace/executeCommand', execute_command_params, execute_callback)

        -- local ok, res = pcall(vim.lsp.buf.execute_command, execute_comand_params)
        -- vim.lsp.buf.execute_command(execute_command_params)

        -- if not ok then
        --     error('TODO error handling')
        -- -- else
        -- --     vim.notify('[go_to_source_definition] no error')
        -- end

        -- return ok

    end,
}

---@class UserLspConfig
local M = {}

M.servers = {
    -- clangd = {},
    -- gopls = {},
    -- pyright = {},
    tsserver = {
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

                includeInlayParameterNameHints = 'all', -- 'none' | 'literals' | 'all';
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayVariableTypeHintsWhenTypeMatchesName = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
            },
        },

        -- maps to lspconfig's `commands` option
        commands = {
            TypescriptOrganizeImports = {
                typescript_commands.organize_imports,
                description = "Organize imports"
            },
            -- _typescript.goToSourceDefinition integration
            TypescriptGoToSourceDefinition = {
                typescript_commands.go_to_source_definition,
                description = "Go to source definition"
            }
        },

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
            completions = {
                completeFunctionCalls = true,
            },
        },
    },

    html = {
        filetypes = {
            'angular.html',
            'html', 'templ',
        },
    },
    -- TODO: how to configure tailwind to attach to .pug files ?
    -- tailwindcss = {
    --     filetypes = {'html', 'css', 'javascript', 'typescript', 'tsx', 'pug'},
    --     tailwindCSS = {
    --         emmetCompletions = true,
    --         includeLanguages = {
    --             pug = 'html',
    --             -- plaintext = 'html',
    --         },
    --     },
    -- },

    rust_analyzer = {

        -- maps to lspconfig's `cmd` option
        -- cmd = { '/home/louis/.cargo/bin/rust-analyzer' },

        ["rust-analyzer"] = {
            diagnostics = {
                enable = true,
                -- experimental = { enable = true },
            },
            cargo = {
                features = 'all',
                buildScripts = {
                    enable = true,
                },
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
        Lua = {
            telemetry = { enable = false },

            hint = { enable = true }, -- TODO: enable inlay hints in nvim >=0.10

            runtime = { version = 'LuaJIT' },

            -- Make the server aware of Neovim runtime files
            workspace = {
                checkThirdParty = false,
                -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#lua_ls
                --
                library = {
                    vim.env.VIMRUNTIME

                    -- Depending on the usage, you might want to add additional paths here.
                    -- E.g.: For using `vim.*` functions, add vim.env.VIMRUNTIME/lua.
                    -- "${3rd}/luv/library"
                    -- "${3rd}/busted/library",
                }
                --
                -- -- or pull in all of 'runtimepath'. NOTE: this is a lot slower:
                --
                -- library = vim.api.nvim_get_runtime_file("", true)
            },

            completion = {
                callSnippet = 'Replace',
            },
        },
    },

    bashls = {
        filetypes = {
            'zsh', 'bash',

            -- default filetypes
            'sh',
        },
    },

    jsonls = {
        json = {
            schemas = {
                {
                    fileMatch = "tsconfig*.json",
                    url = "https://json.schemastore.org/tsconfig"
                },
                {
                    fileMatch = "package.json",
                    url = "https://json.schemastore.org/package.json"
                },
                -- {
                --     fileMatch = "nest-cli.json",
                --     url = "https://json.schemastore.org/nest-cli"
                -- },
            }
        }
    },

    -- docker_compose_language_service = {
    --     -- default is 'yaml.docker-compose'
    --     -- filetypes = { 'yaml.docker-compose' },
    -- },
    angularls = {
        filetypes = {
            'angular.html',
            -- defaults
            'typescript', 'html', 'typescriptreact', 'typescript.tsx'
        },
    },
}

---@param client vim.lsp.Client
---@param bufnr integer
function M.on_attach(client, bufnr)
    local map = function(modes, keys, func, desc)
        if desc then
            desc = 'LSP: ' .. desc
        end

        vim.keymap.set(modes, keys, func, { buffer = bufnr, desc = desc })
    end

    local nmap = function(keys, func, desc)
        map('n', keys, func, desc)
    end

    local imap = function(keys, func, desc)
        map('i', keys, func, desc)
    end

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
    nmap('<A-Enter>', vim.lsp.buf.code_action, 'Code Action')


    local telescope_lsp_options = {
        layout_strategy = 'vertical',
        -- layout_config = {
        -- },
        fname_width = 70,
    }


    nmap('gd', function() require('telescope.builtin').lsp_definitions(telescope_lsp_options) end, '[G]oto [D]efinition')
    nmap('gr', function() require('telescope.builtin').lsp_references(telescope_lsp_options) end, '[G]oto [R]eferences')
    nmap('gI', function() require('telescope.builtin').lsp_implementations(telescope_lsp_options) end,
        '[G]oto [I]mplementation')
    nmap('<leader>D', function() require('telescope.builtin').lsp_type_definitions(telescope_lsp_options) end,
        'Type [D]efinition')
    nmap('<leader>ds', function() require('telescope.builtin').lsp_document_symbols(telescope_lsp_options) end,
        '[D]ocument [S]ymbols')
    nmap('<leader>ws', function() require('telescope.builtin').lsp_dynamic_workspace_symbols(telescope_lsp_options) end,
        '[W]orkspace [S]ymbols')

    -- See `:help K` for why this keymap
    nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('<C-s>', vim.lsp.buf.signature_help, '[S]ignature Documentation')
    imap('<C-s>', vim.lsp.buf.signature_help, '[S]ignature Documentation')

    -- Lesser used LSP functionality
    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

    -- Create a command `:Format` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
        vim.lsp.buf.format()
    end, { desc = 'Format current buffer with LSP' })


    -- Create an autocommand to highlight hovered word using attached LSP
    local highlight_augroup_name = "LspDocumentHighlightGroup"
    local highlight_augroup = vim.api.nvim_create_augroup(highlight_augroup_name, { clear = true })
    local highlight_augroup_opts = function(callback)
        return {
            callback = callback,
            group = highlight_augroup,
            buffer = bufnr,
        }
    end
    if client.supports_method('textDocument/documentHighlight') then
        vim.api.nvim_create_autocmd('CursorHold', highlight_augroup_opts(vim.lsp.buf.document_highlight))
        vim.api.nvim_create_autocmd('CursorHoldI', highlight_augroup_opts(vim.lsp.buf.document_highlight))
        vim.api.nvim_create_autocmd('CursorMoved', highlight_augroup_opts(vim.lsp.buf.clear_references))
        vim.api.nvim_create_autocmd('CursorMovedI', highlight_augroup_opts(vim.lsp.buf.clear_references))
    end


    -- Enable inlay hints
    -- if client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
    if client.supports_method('textDocument/inlayHint') then
        if vim.lsp.inlay_hint and type(vim.lsp.inlay_hint.enable) == 'function' then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
    end
end

return M
