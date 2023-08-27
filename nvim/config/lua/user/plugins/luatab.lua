return {
    {
        'alvarosevilla95/luatab.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        config = function()
            -- highlight groups are defined in onedark config
            require('luatab').setup {
                separator = function(index)
                    -- return ''
                    return ''
                end
            }
        end
    },
}
