local SymbolKind = vim.lsp.protocol.SymbolKind

---@type LazySpec
return {
    {
        "VidocqH/lsp-lens.nvim",
        -- https://github.com/VidocqH/lsp-lens.nvim?tab=readme-ov-file#configs
        opts = {
            enable = true,
            include_declaration = false,  -- Reference include declaration
            sections = {        -- Enable / Disable specific request, formatter example looks 'Format Requests'
                definition = false,
                references = function(count)
                    return count .. " reference" .. (count ~= 1 and "s" or "")
                end,
                implements = function(count)
                    return count .. " implementation" .. (count ~= 1 and "s" or "")
                end,
                git_authors = function(latest_author, count)
                    return " " .. latest_author .. (count - 1 == 0 and "" or (" + " .. count - 1))
                end,
            },
            ignore_filetype = { "prisma", },
            -- Target Symbol Kinds to show lens information
            target_symbol_kinds = {
                SymbolKind.Function,
                SymbolKind.Method,
                SymbolKind.Interface
            },
            -- Symbol Kinds that may have target symbol kinds as children
            wrapper_symbol_kinds = { SymbolKind.Class, SymbolKind.Struct },
        },
    }
}
