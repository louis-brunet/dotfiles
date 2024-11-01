---@type LazySpec
local M = {
    {
        'louis-brunet/llama.vim',

        -- dependencies = {
        --     'projekt0n/github-nvim-theme'
        -- },

        config = function(_, opts)
            vim.fn.call('llama#init', {})

            -- customized llama.vim highlight llama_hf_info and llama_hg_hint
            -- see nvim/config/lua/user/lazy-spec/theme.lua
        end
    }
}

return M
