local render_markdown_filetypes = { "markdown", "Avante" }

---@type LazySpec
return {
    {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
            file_types = render_markdown_filetypes,
            pipe_table = { style = "normal", preset = "double" },
        },
        ft = render_markdown_filetypes,
        -- dependencies = {'hrsh7th/nvim-cmp'},
        config = function(_, opts)
            require("render-markdown").setup(opts)
            -- local cmp = require('cmp')
            -- cmp.setup({
            --     sources = cmp.config.sources({
            --         { name = 'render-markdown' },
            --     }),
            -- })
        end,
    },
    {
        -- Auto-magically format markdown tables under the cursor
        "Kicamon/markdown-table-mode.nvim",
        ft = render_markdown_filetypes,
        opts = {
            -- see https://github.com/Kicamon/markdown-table-mode.nvim?tab=readme-ov-file#configuration
            -- filetype = {},
            options = {
                insert = true,        -- when typing "|"
                insert_leave = true,  -- when leaving insert
            },
        },
        config = true,
    },
}
