local render_markdown_filetypes = { "markdown", "Avante" }

---@type LazySpec
return {
    -- Make sure to set this up properly if you have lazy=true
    'MeanderingProgrammer/render-markdown.nvim',
    opts = {
        file_types = render_markdown_filetypes,
    },
    ft = render_markdown_filetypes,
}
