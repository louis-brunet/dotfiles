---@type LazySpec
return {
    -- {
    --     'vhyrro/luarocks.nvim',
    --     -- dependencies = {
    --     --     'rcarriga/nvim-notify',
    --     -- },
    --
    --     opts = {
    --         -- rocks = { 'lua-curl', 'nvim-nio', 'mimetypes', 'xml2lua' },
    --     },
    --
    --     config = function(_, opts)
    --         require("luarocks").setup(opts)
    --     end,
    -- },
    {
        "rest-nvim/rest.nvim", -- https://github.com/rest-nvim/rest.nvim

        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            {
                'vhyrro/luarocks.nvim',

                config = function(_, opts)
                    require('luarocks').setup(opts)
                end,
            },
        },

        ft = { 'http' },

        keys = {
            { '<leader>rq', '<CMD>Rest run<CR>', buffer = true, desc = '[r]est-nvim re[q]uest' },

            -- NOTE: there is no binding to preview cURL cmd in rest.nvim v2
        },

        opts = {
            -- TODO: use opts for rest.nvim v2
        },

        config = function(_, opts)
            local rest_nvim = require('rest-nvim')
            rest_nvim.setup(opts)
        end,
    }
}
