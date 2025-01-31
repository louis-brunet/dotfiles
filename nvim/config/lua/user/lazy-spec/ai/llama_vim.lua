local llama_server_origin = "http://127.0.0.1:8012"
local llama_endpoints = {
    enabled = llama_server_origin .. "/infill",
    disabled = "__DISABLED__"
}

local notify = function(message)
    vim.notify(
        message,
        vim.log.levels.INFO,
        { title = "llama.vim" }
    )
end

local function are_llm_completions_enabled()
    local opts = vim.g.llama_config
    return opts.endpoint == llama_endpoints.enabled
end

local function notify_llm_completions_status()
    local message = "LLM completions are "

    if are_llm_completions_enabled() then
        message = message .. "enabled"
    else
        message = message .. "disabled"
    end

    notify(message)
end

local function toggle_llm_completions()
    local opts = vim.g.llama_config
    if opts.endpoint ~= llama_endpoints.disabled then
        opts.endpoint = llama_endpoints.disabled
    else
        opts.endpoint = llama_endpoints.enabled
    end
    vim.g.llama_config = opts

    notify_llm_completions_status()
end

---@type LazySpec
local M = {
    {
        "louis-brunet/llama.vim",

        init = function()
            -- NOTE: see :help llama_config
            vim.g.llama_config = {
                endpoint = llama_endpoints.enabled,
                -- api_key = "",
                -- n_prefix = 256,
                -- n_suffix = 64,
                -- n_predict = 128,
                -- t_max_prompt_ms = 500,
                -- t_max_predict_ms = 500,
                -- show_info = 2,
                -- auto_fim = true,
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

            vim.api.nvim_create_user_command(
                "LlmCompletionsToggle",
                toggle_llm_completions,
                { desc = "llama.vim: toggle completions" }
            )

            vim.api.nvim_create_user_command(
                "LlmCompletionsStatus",
                notify_llm_completions_status,
                { desc = "llama.vim: show completions status" }
            )
        end,
    },
}

return M
