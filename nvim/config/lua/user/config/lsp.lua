local M = {}

local function ts_organize_imports()
    local params = {
        command = "_typescript.organizeImports",
        arguments = {
            vim.api.nvim_buf_get_name(0), -- organize for current buffer
            { skipDestructiveCodeActions = false }, -- delete unused imports
        },
        title = ""
    }
    vim.lsp.buf.execute_command(params)
end


M.servers = {
    -- clangd = {},
    -- gopls = {},
    -- pyright = {},
    tsserver = {
        -- maps to lspconfig's `init_options` (!= `settings`)
        init_options = {
            hostInfo = "neovim",
            preferences = {
                quotePreference = "single",
            },
        },

        -- maps to lspconfig's `commands` option
        commands = {
            OrganizeImports = {
                ts_organize_imports,
                description = "Organize Imports"
            }
        },

        settings = {
            typescript = {
                format = {
                    indentSize = vim.o.shiftwidth,
                    convertTabsToSpaces = vim.o.expandtab,
                    tabSize = vim.o.tabstop,
                },
            },
            javascript = {
                format = {
                    indentSize = vim.o.shiftwidth,
                    convertTabsToSpaces = vim.o.expandtab,
                    tabSize = vim.o.tabstop,
                },
            },
            completions = {
                completeFunctionCalls = true,
            },
        },
    },
    html = {},
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
        ["rust-analyzer"] = {
            cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                runBuildScripts = true,
            },
            -- Add clippy lints for Rust.
            checkOnSave = {
                allFeatures = true,
                command = "clippy",
                extraArgs = { "--no-deps", "-A", "clippy::needless_return" },
            },
            procMacro = {
                enable = true,
                ignored = {
                    ["async-trait"] = { "async_trait" },
                    ["napi-derive"] = { "napi" },
                    ["async-recursion"] = { "async_recursion" },
                },
            },
            -- check = {
            --     -- command = "clippy",
            --     overrideCommand = { "cargo", "clippy", "--workspace", "--message-format=json", "--all-targets", "--",
            --         "-A", "clippy::needless_return", },
            -- },
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
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            -- hint = { enable = true }, -- enable inlay hints
        },
    },
}

M.on_attach = function(client, bufnr)
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

    nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
    nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

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

    local function trigger_highlight(callback)
        if client.supports_method('textDocument/documentHighlight') then
            return highlight_augroup_opts(callback)
        end
    end
    vim.api.nvim_create_autocmd("CursorHold", trigger_highlight(vim.lsp.buf.document_highlight))
    vim.api.nvim_create_autocmd("CursorHoldI", trigger_highlight(vim.lsp.buf.document_highlight))
    vim.api.nvim_create_autocmd("CursorMoved", trigger_highlight(vim.lsp.buf.clear_references))
    vim.api.nvim_create_autocmd("CursorMovedI", trigger_highlight(vim.lsp.buf.clear_references))
end

return M
