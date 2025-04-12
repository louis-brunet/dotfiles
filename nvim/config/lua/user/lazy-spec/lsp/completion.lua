-- local function get_llm_completion_module()
--     local llm_completion = require('llm.completion')
--     if not llm_completion then
--         vim.notify('[lsp/completion.lua] module llm.completion not found. Either install it or remove the relevant lines from lazy-spec/lsp/completion.lua', vim.log.levels.WARN)
--     end
--     return llm_completion
-- end

---@type LazySpec
local M = {
    {
        -- Autocompletion
        'hrsh7th/nvim-cmp',
        event = 'VeryLazy',
        dependencies = {
            -- Snippet Engine & its associated nvim-cmp source
            'L3MON4D3/LuaSnip',
            'saadparwaiz1/cmp_luasnip',

            -- Adds LSP completion capabilities
            'hrsh7th/cmp-nvim-lsp',

            -- Adds LSP signature help
            'hrsh7th/cmp-nvim-lsp-signature-help',

            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',

            -- Adds a number of user-friendly snippets
            'rafamadriz/friendly-snippets',
        },
        config = function(_, _)
            -- [[ Configure nvim-cmp ]]
            -- See `:help cmp`
            local cmp = require 'cmp'
            local luasnip = require 'luasnip'
            require('luasnip.loaders.from_vscode').lazy_load()
            luasnip.config.setup {}

            cmp.setup {
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert {
                    ['<C-n>'] = function()
                        if cmp.visible() then
                            cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
                        else
                            cmp.complete()
                        end
                    end,
                    ['<C-p>'] = function()
                        if cmp.visible() then
                            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
                        else
                            cmp.complete()
                        end
                    end,
                    ['<C-e>'] = cmp.mapping.abort(),
                    ['<C-y>'] = cmp.mapping.confirm({ select = false }),
                    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete {},
                    ['<CR>'] = cmp.mapping.confirm {
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    },
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        -- local llm_completion = get_llm_completion_module()
                        --
                        -- if llm_completion and llm_completion.suggestion then
                        --     llm_completion.complete()
                        -- elseif cmp.visible() then
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                    ['<S-Tab>'] = cmp.mapping(function(fallback)
                        -- local llm_completion = get_llm_completion_module()
                        --
                        -- if llm_completion and llm_completion.suggestion then
                        --     llm_completion.cancel()
                        --     llm_completion.suggestion = nil
                        -- elseif cmp.visible() then
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.locally_jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                },
                sources = cmp.config.sources({
                    { name = "nvim_lsp_signature_help" },
                    { name = "nvim_lsp" },
                    { name = "path" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                })
            }
        end
    }
}

return M
