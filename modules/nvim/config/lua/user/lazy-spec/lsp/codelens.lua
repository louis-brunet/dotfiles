---@type LazySpec
return {
    {
        "VidocqH/lsp-lens.nvim",
        event = "VeryLazy",
        config = function(_, _)
            local SymbolKind = vim.lsp.protocol.SymbolKind

            ---@param count integer
            ---@return string
            local function display_references(count)
                return count .. " reference" .. (count ~= 1 and "s" or "")
            end

            ---@param count integer
            ---@return string
            local function display_implementations(count)
                return count .. " implementation" .. (count ~= 1 and "s" or "")
            end

            ---@param latest_author string
            ---@param count integer
            ---@return string
            local function display_git_authors(latest_author, count)
                return (" %s%s"):format(
                    latest_author,
                    (count - 1 == 0 and "" or (" + " .. count - 1))
                )
            end

            -- https://github.com/VidocqH/lsp-lens.nvim?tab=readme-ov-file#configs
            local opts = {
                enable = true,
                include_declaration = false,  -- Reference include declaration
                sections = {              -- Enable / Disable specific request, formatter example looks 'Format Requests'
                    definition = false,
                    references = display_references,
                    implements = display_implementations,
                    git_authors = display_git_authors,
                },
                ignore_filetype = { "prisma" },
                -- Target Symbol Kinds to show lens information
                target_symbol_kinds = {
                    SymbolKind.Function,
                    SymbolKind.Method,
                    SymbolKind.Interface,
                    -- vim.lsp.protocol.SymbolKind.Function,
                    -- vim.lsp.protocol.SymbolKind.Method,
                    -- vim.lsp.protocol.SymbolKind.Interface,
                },
                -- Symbol Kinds that may have target symbol kinds as children
                wrapper_symbol_kinds = {
                    SymbolKind.Class,
                    SymbolKind.Struct,
                    -- vim.lsp.protocol.SymbolKind.Class,
                    -- vim.lsp.protocol.SymbolKind.Struct,
                },
            }

            require("lsp-lens").setup(opts)
        end,
    },
}
