---@type LazySpec
local M = {
    {
        "louis-brunet/llama.vim",

        -- dependencies = {
        --     'projekt0n/github-nvim-theme'
        -- },


        init = function()
            -- NOTE: see :help llama_config
            vim.g.llama_config = {
                -- endpoint = "http://127.0.0.1:8012/infill",
                -- api_key = "",
                -- n_prefix = 256,
                -- n_suffix = 64,
                -- n_predict = 128,
                -- t_max_prompt_ms = 500,
                -- t_max_predict_ms = 500,
                -- show_info = 2,
                auto_fim = true,
                -- max_line_suffix = 8,
                -- max_cache_keys = 250,
                -- ring_n_chunks = 16,
                -- ring_chunk_size = 64,
                -- ring_scope = 1024,
                -- ring_update_ms = 1000,
            }

            -- vim.fn.call("llama#init", {})

            -- NOTE: customized llama.vim highlight llama_hf_info and
            -- llama_hg_hint; see nvim/config/lua/user/lazy-spec/theme.lua
        end,
    },
}

return M
