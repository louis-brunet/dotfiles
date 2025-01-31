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

            local notify = function(message)
                vim.notify(
                    message,
                    vim.log.levels.INFO,
                    { title = "llama.vim" }
                )
            end

            local function toggle_llm_completions()
                local opts = vim.g.llama_config
                if opts.endpoint ~= "" then
                    opts.endpoint = ""
                else
                    opts.endpoint = "http://127.0.0.1:8012/infill"
                end
                vim.g.llama_config = opts

                local is_enabled = opts.endpoint ~= ""
                local message = "LLM completions are "
                if is_enabled then
                    message = message .. "enabled"
                else
                    message = message .. "disabled"
                end

                notify(message)
            end

            vim.api.nvim_create_user_command(
                "ToggleCompletions",
                toggle_llm_completions,
                { desc = "Toggle llama.vim completions" }
            )
        end,
    },
}

return M
