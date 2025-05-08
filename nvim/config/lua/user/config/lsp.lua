---@class UserLspConfig
local M = {}

M.servers_to_enable = {
    "angularls",
    "bashls",
    "dockerls",
    "eslint",
    "harper_ls",
    "html",
    "jsonls",
    "lua_ls",
    "pyright",
    "ruff",
    "rust_analyzer",
    "tailwindcss",
    "terraformls",
    "ts_ls",
    "yamlls",
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

    for _, keymap_lhs in ipairs({ "grn", "<leader>rn" }) do
        nmap(keymap_lhs,
            vim.lsp.buf.rename,
            "[r]e[n]ame")
    end

    local ok, actions_preview = pcall(require, "actions-preview")
    local code_action
    if ok then
        code_action = actions_preview.code_actions
    else
        code_action = vim.lsp.buf.code_action
    end
    for _, keymap_lhs in ipairs({ "<A-Enter>", "gra", "<leader>ca" }) do
        nmap(keymap_lhs,
            code_action,
            "code [a]ction")
    end

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
    nmap("grr",
        function()
            require("telescope.builtin").lsp_references(
                telescope_lsp_options)
        end, "[G]oto [R]eferences")
    for _, implementation_keymap_lhs in ipairs({ "gI", "gri" }) do
        nmap(implementation_keymap_lhs,
            function()
                require("telescope.builtin").lsp_implementations(
                    telescope_lsp_options)
            end,
            "[G]oto [I]mplementation")
    end
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

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_foldingRange) then
        local current_window = vim.api.nvim_get_current_win()
        vim.api.nvim_set_option_value("foldmethod", "expr",
            { win = current_window })
        vim.api.nvim_set_option_value("foldexpr", "v:lua.vim.lsp.foldexpr()",
            { win = current_window })
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentColor) then
        -- NOTE: vim.lsp.document_color is set to be released in nvim 0.12.
        -- It is disabled by default like inlay hints.
        local enable_document_color = (vim.lsp.document_color or {}).enable
        if type(enable_document_color) == "function" then
            enable_document_color(true, bufnr)
        end
    end
end

return M
