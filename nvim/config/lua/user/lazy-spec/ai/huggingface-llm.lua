local HF_TEMPERATURE = 0.0
local HF_TOP_P = 0.0
local HF_TOP_K = 40
-- local HF_NUM_PREDICT = 128
local HF_NUM_PREDICT = 64
-- local HF_CTX_SIZE = 8192
-- local HF_CTX_SIZE = 4096
-- local HF_CTX_SIZE=2048
-- local HF_CTX_SIZE = 1500
local HF_CTX_SIZE = 1024
-- local HF_CTX_SIZE = 512
-- local HF_CTX_SIZE = 256
local HF_CTX_PADDING = 0
-- local HF_CTX_PADDING = math.floor(HF_CTX_SIZE * 0.3)

--- https://github.com/huggingface/llm.nvim/tree/main?tab=readme-ov-file#configuration
---@type table<string, llm_config>
local hf_default_opts = {
    ollama = {
        backend = "ollama",             -- backend ID, "huggingface" | "ollama" | "openai" | "tgi"

        url = "http://localhost:11434", -- llm-ls uses "/api/generate"

        ---@type OllamaApiGenerateRequestBody
        request_body = { -- https://github.com/ollama/ollama/blob/main/docs/api.md#parameters
            options = {  -- https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
                temperature = HF_TEMPERATURE,
                top_p = HF_TOP_P,
                num_predict = HF_NUM_PREDICT,
                -- num_ctx = math.floor(HF_CTX_SIZE * 1.3) + HF_NUM_PREDICT,
                num_ctx = HF_CTX_SIZE + HF_NUM_PREDICT + HF_CTX_PADDING,
                top_k = HF_TOP_K,
                -- repeat_last_n = 128,
            },
            keep_alive = "5h",
            raw = true,
            -- template = "{{ .Prompt }}"
        },
        context_window = HF_CTX_SIZE,

        -- enable_suggestions_on_startup = true,
        -- enable_suggestions_on_files = "*", -- pattern matching syntax to enable suggestions on specific files, either a string or a list of strings
        -- disable_url_path_completion = false, -- cf Backend
        -- debounce_ms = 150,
        -- accept_keymap = "<Tab>",
        -- dismiss_keymap = "<S-Tab>",
        -- tls_skip_verify_insecure = false,
        --
        -- -- llm-ls configuration, cf llm-ls section
        -- lsp = {
        --     bin_path = nil,
        --     host = nil,
        --     port = nil,
        --     cmd_env = nil, -- or { LLM_LOG_LEVEL = "DEBUG" } to set the log level of llm-ls
        --     version = "0.5.3",
        -- },
    },
    llamacpp = {
        backend = "llamacpp",

        url = "http://localhost:8080",

        ---@type LlamacppApiGenerateRequestBody
        request_body = {
            temperature = HF_TEMPERATURE,
            top_p = HF_TOP_P,
            top_k = HF_TOP_K,
        },
        context_window = HF_CTX_SIZE,
    },
    openai = {
        backend = "openai",

        url = "http://localhost:9000",

        ---@type OpenAiApiGenerateRequestBody
        request_body = {
            temperature = HF_TEMPERATURE,
            top_p = HF_TOP_P,
            top_k = HF_TOP_K,
        },
        context_window = HF_CTX_SIZE,
    },
    -- mistral = {
    -- FIXME: openai backend is not compatible " ERROR [LLM] serde json error: data did not match any variant of untagged enum OpenAIAPIResponse"
    --     backend = "openai",
    --
    --     model = "codestral-2405", -- found in https://console.mistral.ai/limits/
    --
    --     disable_url_path_completion = true,
    --     url = "https://codestral.mistral.ai/v1/fim/completions",
    --     api_token = vim.env.MISTRAL_API_KEY, -- https://console.mistral.ai/codestral
    --
    --     ---@type OpenAiApiGenerateRequestBody
    --     request_body = {
    --         temperature = HF_TEMPERATURE,
    --         top_p = HF_TOP_P,
    --         top_k = HF_TOP_K,
    --     },
    --     context_window = HF_CTX_SIZE,
    -- },
}


---@type table<string, llm_config>
local hf_model_opts = {

    starcoder2 = {
        model = "starcoder2:3b",
        -- model = "starcoder2:7b",
        tokens_to_clear = { "<|endoftext|>", "<file_sep>" },
        fim = {
            enabled = true,
            prefix = "<fim_prefix>",
            middle = "<fim_middle>",
            suffix = "<fim_suffix>",
        },
        tokenizer = {
            repository = "bigcode/starcoder2-3b",
            -- repository = "bigcode/starcoder2-7b",
        },
    },

    qwen = {
        -- model = "qwen2.5-coder:1.5b-base-q4_K_M",
        -- model = "qwen2.5-coder:1.5b-base", -- same as qwen2.5-coder:1.5b-base-q4_K_M
        -- model = "qwen2.5-coder:1.5b-base-q8_0",
        -- model = "qwen2.5-coder:1.5b-base-fp16",
        -- model = "qwen2.5-coder:7b-base", -- same as qwen2.5-coder:7b-base-q4_K_M
        -- model = "qwen2.5-coder:7b-base-q4_K_M",
        -- model = "qwen2.5-coder:7b-base-q8_0",
        -- model = "qwen2.5-coder:1.5b-instruct-q4_K_M",
        -- model = "qwen2.5-coder:1.5b-instruct",
        -- model = "qwen2.5-coder:1.5b-instruct-q8_0",
        -- model = "qwen2.5-coder:1.5b-instruct-fp16",
        -- model = "qwen2.5-coder:7b-instruct-q2_K",
        -- model = "qwen2.5-coder:7b-instruct-q4_0",
        model = "qwen2.5-coder:7b-instruct-q4_K_M",
        -- model = "qwen2.5-coder:7b-instruct-q5_K_M",
        -- model = "qwen2.5-coder:7b-instruct-q8_0",
        tokens_to_clear = { "<|endoftext|>", "<|file_sep|>", "<|fim_pad|>", "<|cursor|>" },
        fim = {
            enabled = true,
            prefix = "<|fim_prefix|>",
            middle = "<|fim_middle|>",
            suffix = "<|fim_suffix|>",
        },
        tokenizer = {
            -- repository = "Qwen/Qwen2.5-Coder-7B",
            repository = "Qwen/Qwen2.5-Coder-1.5B",
            -- repository = "Qwen/Qwen2.5-Coder-1.5B-Instruct",
            -- repository = "Qwen/Qwen2.5-Coder-7B-Instruct",
        },
    },

    codellama = {
        model = "codellama:code",
        -- model = "codellama:34b-code",
        tokens_to_clear = { "<EOT>" },
        fim = {
            enabled = true,
            prefix = "<PRE> ",
            middle = " <MID>",
            suffix = " <SUF>",
        },
        tokenizer = {
            repository = "codellama/CodeLlama-7b-hf",
            -- repository = "codellama/CodeLlama-34b-hf",
        }
    },

    deepseek_coder = {
        -- model = "deepseek-coder:1.3b-base",
        model = "deepseek-coder:1.3b-base-q8_0",
        -- model = "deepseek-coder:1.3b-base-fp16",
        -- model = "deepseek-coder:6.7b-base-q4_0",
        -- model = "deepseek-coder:6.7b-base-q4_K_M",
        tokens_to_clear = { "<｜begin▁of▁sentence｜>", "<|endoftext|>" },
        fim = {
            enabled = true,
            -- NOTE: '｜' != '|'
            prefix = "<｜fim▁begin｜>",
            middle = "<｜fim▁end｜>",
            suffix = "<｜fim▁hole｜>",
        },
        tokenizer = {
            -- repository = "deepseek-ai/deepseek-coder-1.3b-base",
            repository = "deepseek-ai/deepseek-coder-6.7b-base",
        },
    },
    deepseek_coder_v2 = {
        -- model = "deepseek-coder-v2:16b-lite-base-q2_K",
        model = "deepseek-coder-v2:16b-lite-base-q4_0",
        -- model = "deepseek-coder-v2:16b-lite-base-q4_K_M",
        tokens_to_clear = {},
        fim = {
            enabled = true,
            -- NOTE: '｜' != '|'
            prefix = "<｜fim▁begin｜>",
            middle = "<｜fim▁end｜>",
            suffix = "<｜fim▁hole｜>",
        },
        tokenizer = {
            repository = "deepseek-ai/DeepSeek-V2-Lite",
        },
    },

    -- FIXME: no completions are shown for codegemma
    codegemma = {
        model = "codegemma:2b-code",
        tokens_to_clear = { "<|file_separator|>" },
        fim = {
            enabled = true,
            prefix = "<|fim_prefix|>",
            middle = "<|fim_middle|>",
            suffix = "<|fim_suffix|>",
        },
        tokenizer = {
            repository = "google/codegemma-2b",
        },
    },

    -- TODO: codestral's fim template is backwards (suffix then prefix)
    -- codestral = {
    --     model = "",
    --     -- tokens_to_clear = { "<|file_separator|>" },
    --     fim = {
    --         enabled = false,
    --     },
    --     tokenizer = {
    --         repository = "",
    --     },
    -- },

    -- codestral = {
    --     model = "codestral:22b",
    --     ---@type OllamaApiGenerateRequestBody
    -- --     request_body = {
    -- --         options = {
    -- --             stop = { "[INST]", "[/INST]", "[SUFFIX]", "[PREFIX]", "</s>" },
    -- --         },
    -- --     },
    --     tokens_to_clear = { "[INST]", "[/INST]", "[SUFFIX]", "[PREFIX]", "</s>" },
    --     -- NOTE: codestral's expected format has inverted suffix and prefix compared to what llm-ls expects...
    --     -- "[SUFFIX]{{ .Suffix }}[PREFIX] {{ .Prompt }}"
    --     -- see https://ollama.com/library/codestral:22b
    --     -- llm-ls@13/10/2024 https://github.com/huggingface/llm-ls/blob/59febfea525d7930bf77e1bae85b411631d503e4/crates/llm-ls/src/main.rs#L195
    --     fim = {
    --         enabled = true,
    --         prefix = "[PREFIX]",
    --         middle = "",
    --         suffix = "[SUFFIX]",
    --     },
    --     tokenizer = {
    --         repository = "mistralai/Codestral-22B-v0.1",
    --     },
    -- },

}

---@param backend_default_opts llm_config
---@param model_opts llm_config
---@return llm_config
local function extend_huggingface_llm_opts(backend_default_opts, model_opts)
    local extended = vim.tbl_deep_extend("force", backend_default_opts, model_opts)

    local stop = (extended.request_body.options or {}).stop or {}

    if type(model_opts.tokens_to_clear) == "table" and #model_opts.tokens_to_clear > 0 then
        for _, new_val in ipairs(model_opts.tokens_to_clear) do
            table.insert(stop, new_val)
        end
    end

    if model_opts.fim and model_opts.fim.enabled then
        if model_opts.fim.prefix then
            table.insert(stop, model_opts.fim.prefix)
        end
        if model_opts.fim.middle then
            table.insert(stop, model_opts.fim.middle)
        end
        if model_opts.fim.suffix then
            table.insert(stop, model_opts.fim.suffix)
        end
    end

    if stop and #stop > 0 then
        if extended.backend == "ollama" then
            extended.request_body.options = extended.request_body.options or {}
            extended.request_body.options.stop = stop
        elseif extended.backend == "openai" then
            extended.request_body.stop = stop
        elseif extended.backend == "llamacpp" then
            extended.request_body.stop = stop
        else
            vim.notify('[lazy-spec.ai.huggingface-llm] extend_huggingface_llm_opts: unrecognized backend',
                vim.log.levels.WARN)
        end
    end

    return extended
end

-- local function accept_completion()
--     local llm_completion = require('llm.completion')
--     if not llm_completion.suggestion then
--         return
--     end
--
--     vim.schedule(llm_completion.complete)
-- end
--
-- local function dismiss_completion()
--     local llm_completion = require('llm.completion')
--     if not llm_completion.suggestion then
--         return
--     end
--
--     vim.schedule(function()
--         llm_completion.cancel()
--         llm_completion.suggestion = nil
--     end)
-- end

---@type LazySpec
local M = {
    -- {
    --     'huggingface/llm.nvim',
    --     opts = extend_huggingface_llm_opts(hf_default_opts.ollama, hf_model_opts.qwen),
    --
    --     -- TODO: finish llamacpp config, seems to be working ish
    --     -- opts = extend_huggingface_llm_opts(hf_default_opts.llamacpp, hf_model_opts.qwen),
    --
    --     -- opts = extend_huggingface_llm_opts(hf_default_opts.openai, hf_model_opts.qwen),
    --
    --     -- opts = hf_default_opts.mistral,
    --
    --     config = function(self, opts)
    --         local llm = require('llm')
    --         local llm_keymaps = require('llm.keymaps')
    --
    --         -- Override default keymap setup, see ../lsp/completion keybinds for <Tab> and <S-Tab>
    --         -- https://github.com/huggingface/llm.nvim/blob/main/lua/llm/keymaps.lua
    --         llm_keymaps.setup_done = true
    --         llm.setup(opts)
    --     end
    -- },

}

return M
