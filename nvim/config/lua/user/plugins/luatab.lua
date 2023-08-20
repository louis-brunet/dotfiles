return {
    {
        'alvarosevilla95/luatab.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        config = function()
            vim.cmd.highlight("TabLineSel guibg=#31353f guifg=#999999")
            vim.cmd.highlight("TabLine guibg=#31353f guifg=#555555")
            require('luatab').setup {
                separator = function(index)
                    -- return ''
                    return ''
                end
            }
        end
    },
}
