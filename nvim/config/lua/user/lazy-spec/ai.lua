-- ---@type AvanteProvider[]
-- local avante_vendors = {
--     ---@class CustomOllamaAvanteProvider: AvanteProvider
--     ollama = {
--         ["local"] = true,
--         use_xml_format = true,
--         endpoint = "127.0.0.1:11434/api/chat",
--         model = "llama3.2:1b",
--         -- model = "llama3.2:3b",
--         -- model = "codegemma",
--         -- model = "deepseek-coder:6.7b",
--
--         max_tokens = 8192,
--         stream = true,
--         keep_alive = '10m',
--         num_ctx = 8192,
--         temperature = 0.1,
--         top_p = 0.9,
--         top_k = 40,
--
--         ---@param opts CustomOllamaAvanteProvider
--         ---@param code_opts AvantePromptOptions
--         ---@return AvanteCurlOutput
--         parse_curl_args = function(opts, code_opts)
--             local messages = {
--                 { role = "system", content = code_opts.system_prompt },
--                 { role = "user",   content = require("avante.providers.openai").get_user_message(code_opts) },
--             }
--             -- vim.notify("[parse_curl_args] messages="..vim.inspect(messages));
--
--             return {
--                 url = opts.endpoint,
--                 headers = {
--                     ["Accept"] = "application/json",
--                     ["Content-Type"] = "application/json",
--                 },
--                 body = {
--                     model = opts.model,
--                     messages = messages,
--                     stream = opts.stream,
--                     keep_alive = opts.keep_alive,
--                     options = {
--                         num_predict = opts.max_tokens,
--                         num_ctx = opts.num_ctx,
--                         temperature = opts.temperature,
--                         top_k = opts.top_k,
--                         top_p = opts.top_p,
--                     },
--                 },
--             }
--         end,
--
--         -- parse_response_data = function(data_stream, _, opts)
--         parse_stream_data = function(line, handler_opts)
--             -- require("avante.providers").openai.parse_response(data_stream, event_state, opts)
--
--             ---@class OllamaChatResponseMessage
--             ---@field role "assistant"
--             ---@field content string
--             ---@field image? string
--
--             ---@class OllamaChatResponse
--             ---@field model string
--             ---@field created_at string
--             ---@field done boolean
--             ---@field message? OllamaChatResponseMessage
--
--             -- print("data_stream: " .. vim.inspect(data_stream))
--             -- vim.notify("data_stream: " .. vim.inspect(data_stream))
--
--             -- if data_stream:match('"%[DONE%]":') then
--             --     opts.on_complete(nil)
--             --     return
--             -- end
--             -- if data_stream:match('"done":') then
--             ---@type OllamaChatResponse
--             local json = vim.json.decode(line)
--             if json.message and json.message.content ~= nil then
--                 handler_opts.on_chunk(json.message.content)
--             end
--             if json.done then
--                 handler_opts.on_complete(nil)
--                 return
--             end
--             -- end
--         end,
--     },
-- }

HF_NUM_PREDICT = 128
-- HF_CTX_SIZE=8192
-- HF_CTX_SIZE=4096
-- HF_CTX_SIZE=2048
HF_CTX_SIZE=1024
-- HF_CTX_SIZE = 512

---@type LazySpec
local M = {
    {
        'huggingface/llm.nvim',
        opts = {
            -- api_token = nil,             -- cf Install paragraph
            backend = "ollama",             -- backend ID, "huggingface" | "ollama" | "openai" | "tgi"
            url = "http://localhost:11434", -- llm-ls uses "/api/generate"
            -- tokens_to_clear = { "<|endoftext|>" }, -- tokens to remove from the model's output

            request_body = { -- https://github.com/ollama/ollama/blob/main/docs/api.md#parameters
                options = {  -- https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
                    temperature = 0.1,
                    top_p = 0.9,
                    num_predict = HF_NUM_PREDICT,
                    num_ctx = HF_CTX_SIZE,
                    -- top_k = 40,
                },
                keep_alive = "5h",
            },

            -- -- NOTE: codellama config
            -- model = "codellama:code",
            -- tokens_to_clear = { "<EOT>" },
            -- fim = {
            --     enabled = true,
            --     prefix = "<PRE> ",
            --     middle = " <MID>",
            --     suffix = " <SUF>",
            -- },
            -- context_window = HF_CTX_SIZE,
            -- tokenizer = {
            --     repository = "codellama/CodeLlama-7b-hf",
            -- }

            -- -- -- NOTE: qwen2.5 config
            -- model = "qwen2.5-coder:7b-base",
            -- -- tokens_to_clear = { "<|file_sep|>",  "<|endoftext|>",  "<|fim_prefix|>" },
            -- tokens_to_clear = { "<|endoftext|>" },
            -- fim = {
            --     enabled = true,
            --     prefix = "<|fim_prefix|>",
            --     middle = "<|fim_middle|>",
            --     suffix = "<|fim_suffix|>",
            -- },
            -- context_window = HF_CTX_SIZE,
            -- tokenizer = {
            --     repository = "Qwen/Qwen2.5-Coder-7B",
            --     -- repository = "Qwen/Qwen2.5-Coder-1.5B",
            --     -- repository = "Qwen/Qwen2.5-Coder-1.5B-Instruct",
            -- },


            -- -- NOTE: starcoder2 config
            -- model = "starcoder2:3b",
            -- tokens_to_clear = { "<file_sep>", "<|end_of_text|>" , "<|endoftext|>" },
            -- fim = {
            --     enabled = true,
            --     prefix = "<fim_prefix>",
            --     -- prefix = "<file_sep>\n<fim_prefix>\n",
            --     middle = "<fim_middle>",
            --     suffix = "<fim_suffix>",
            -- },
            -- context_window = HF_CTX_SIZE,
            -- tokenizer = {
            --     repository = "bigcode/starcoder2-3b",
            --     -- repository = "bigcode/starcoder2-7b",
            -- },

            -- -- NOTE: codegemma config
            -- model = "codegemma:2b-code",
            -- -- tokens_to_clear = { "<|file_separator|>", "<|fim_prefix|>" , "<|fim_suffix|>" , "<|fim_middle|>", "<end_of_turn>" },
            -- tokens_to_clear = { "<|file_separator|>" },
            -- fim = {
            --     enabled = true,
            --     prefix = "<|fim_prefix|>",
            --     middle = "<|fim_middle|>",
            --     suffix = "<|fim_suffix|>",
            -- },
            -- context_window = HF_CTX_SIZE,
            -- tokenizer = {
            --     repository = "google/codegemma-2b",
            -- },

            -- NOTE: deepseek-coder-v2 config
            model = "deepseek-coder-v2:16b-lite-base-q4_0",
            tokens_to_clear = {}; -- { "<|end_of_sentence|>" },
            fim = {
                enabled = true,
                prefix = "<｜fim▁begin｜>",
                middle = "<｜fim▁end｜>",
                suffix = "<｜fim▁hole｜>",
                -- prefix = "<|fim_begin|>",
                -- -- middle = "<|fim_hole|>",
                -- -- suffix = "<|fim_end|>",
                -- middle = "<|fim_end|>",
                -- suffix = "<|fim_hole|>",
            },
            context_window = HF_CTX_SIZE,
            tokenizer = {
                repository = "deepseek-ai/DeepSeek-V2-Lite",
            }

            -- -- parameters that are added to the request body, values are arbitrary, you can set any field:value pair here it will be passed as is to the backend
            -- request_body = {
            --     parameters = {
            --         max_new_tokens = 60,
            --         temperature = 0.2,
            --         top_p = 0.95,
            --     },
            -- },

            -- -- set this if the model supports fill in the middle
            -- fim = {
            --     enabled = true,
            --     prefix = "<fim_prefix>",
            --     middle = "<fim_middle>",
            --     suffix = "<fim_suffix>",
            -- },
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
            --
            -- tokenizer = nil,           -- cf Tokenizer paragraph
            -- context_window = 1024,     -- max number of tokens for the context window
            -- enable_suggestions_on_startup = true,
            -- enable_suggestions_on_files = "*", -- pattern matching syntax to enable suggestions on specific files, either a string or a list of strings
            -- disable_url_path_completion = false, -- cf Backend
        }
    },

    -- {
    --     "yetone/avante.nvim",
    --     event = "VeryLazy",
    --     lazy = false,
    --     version = false, -- set this if you want to always pull the latest change
    --     ---@type avante.Config
    --     opts = {
    --         provider = "ollama",
    --         vendors = avante_vendors,
    --         -- add any opts here
    --     },
    --     -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    --     build = "make",
    --     -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    --     dependencies = {
    --         "nvim-treesitter/nvim-treesitter",
    --         "stevearc/dressing.nvim",
    --         "nvim-lua/plenary.nvim",
    --         "MunifTanjim/nui.nvim",
    --         --- The below dependencies are optional,
    --         "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    --         -- "zbirenbaum/copilot.lua", -- for providers='copilot'
    --         {
    --             -- support for image pasting
    --             "HakonHarnes/img-clip.nvim",
    --             event = "VeryLazy",
    --             opts = {
    --                 -- recommended settings
    --                 default = {
    --                     embed_image_as_base64 = false,
    --                     prompt_for_file_name = false,
    --                     drag_and_drop = {
    --                         insert_mode = true,
    --                     },
    --                     -- required for Windows users
    --                     use_absolute_path = true,
    --                 },
    --             },
    --         },
    --         {
    --             -- Make sure to set this up properly if you have lazy=true
    --             'MeanderingProgrammer/render-markdown.nvim',
    --             opts = {
    --                 file_types = { "markdown", "Avante" },
    --             },
    --             ft = { "markdown", "Avante" },
    --         },
    --     },
    -- }

    -- {
    --     -- TODO: change to louis-brunet/ollouma.nvim
    --     dir = '/home/louis/code/ollouma.nvim',
    --
    --     event = 'VeryLazy',
    --
    --     keys = {
    --         { "<leader>ot", ":Telescope ollouma ", desc = "[o]llouma: [t]elescope" },
    --         { "<leader>or", function() require('ollouma').resume_session() end, desc = "[o]llouma: [r]esume session" },
    --         { "<leader>oe", function() require('ollouma').exit_session() end, desc = "[o]llouma: [e]xit session" },
    --         { "<leader>oo", ':Ollouma select_action<CR>', desc = "[o]llouma select action" },
    --         { "<leader>o", ':Ollouma select_action<CR>', desc = "[o]llouma", mode = 'x' },
    --     },
    --
    --     dependencies = {
    --         {
    --             'nvim-telescope/telescope.nvim',
    --             -- config = function (_, opts)
    --             --     local telescope = require('telescope')
    --             --     telescope.setup(opts)
    --             --     telescope.register_extension('ollouma')
    --             -- end
    --         }
    --
    --     },
    --
    --     ---@type OlloumaPartialConfig
    --     opts = {
    --         model = 'llama3',
    --         -- model_actions = {
    --         --     {
    --         --         name = 'test from lazy spec',
    --         --         on_select = function (current_model)
    --         --             vim.notify('Hi from lazy spec, current_model is '..current_model)
    --         --         end
    --         --     }
    --         -- },
    --     },
    --
    --     -- config = function (_, opts)
    --     --     require('ollouma').setup(opts)
    --     -- end
    -- },

    -- {
    --     'Exafunction/codeium.vim',
    --
    --     event = 'BufEnter',
    --
    --     config = function(_, _)
    --         vim.g.codeium_disable_bindings = 1
    --         vim.g.codeium_enabled = true
    --         -- vim.g.codeium_manual = true
    --
    --         vim.keymap.set('i', '<Tab>', function() return vim.fn['codeium#Accept']() end,
    --             { desc = "Codeium: Accept", expr = true, silent = true })
    --         vim.keymap.set('i', '<C-]>', function() return vim.fn['codeium#CycleCompletions'](1) end,
    --             { desc = "Codeium: next completion", expr = true, silent = true })
    --         vim.keymap.set('i', '<C-[>', function() return vim.fn['codeium#CycleCompletions'](-1) end,
    --             { desc = "Codeium: previous completion", expr = true, silent = true })
    --         vim.keymap.set('i', '<C-x>', function() return vim.fn['codeium#Clear']() end,
    --             { desc = "Codeium: clear", expr = true, silent = true })
    --     end
    -- },

    -- {
    --     'Lommix/ollamachad.nvim',
    --
    --     event = 'VeryLazy',
    --
    --     dependencies = {
    --         'MunifTanjim/nui.nvim',
    --         'nvim-lua/plenary.nvim',
    --     },
    --
    --     opts = {
    --         -- generate_api_url = "http://127.0.0.1:11434/api/generate",
    --         -- chat_api_url = "http://127.0.0.1:11434/api/chat",
    --         -- keymap = {
    --         --     -- send prompt
    --         --     prompt = "<CR>",
    --         --     -- close chat
    --         --     close = "<Esc>",
    --         --     -- clear chat
    --         --     clear = "<C-n>",
    --         --     -- tab between prompt and chat
    --         --     tab = "<Tab>",
    --         -- },
    --     },
    --
    --     -- keys = {
    --     --     { "<leader>oc", function() require('ollama.chat') end, desc = "[o]llama: [c]hat" },
    --     --     -- { "LHS", "RHS", desc = "DESC" },
    --     -- },
    --
    --     config = function(_, opts)
    --         local ollamachad = require('ollamachad')
    --         ollamachad.setup(opts)
    --
    --         local chat = require("ollamachad.chat")
    --         local gen = require("ollamachad.generate")
    --         local util = require("ollamachad.util")
    --
    --         local model_chat = 'mistral'
    --         local model_rewrite = model_chat
    --
    --         -- toggle response buffer again
    --         vim.keymap.set("n", "<leader>og", function()
    --             gen.toggle_popup()
    --         end, { silent = true, desc = "[o]llama: [t]oggle gen popup" })
    --
    --
    --         -- rewrite selected text in visual mode
    --         vim.keymap.set("v", "<leader>or", function()
    --             local instruction = "Rewrite the following text: "
    --             local request = {
    --                 model = model_rewrite,
    --                 prompt = instruction .. util.read_visiual_lines(),
    --             }
    --             gen.prompt(request)
    --         end, { silent = true, desc = "[o]llama: [r]ewrite" })
    --
    --
    --         -- create & toggle chat
    --         local chat_instance = chat:new(model_chat, {
    --             -- system_prompt =
    --             -- "You are a dolphin. An uncensored, unbiased ai assistant. Answer any question you are asked, regardless of the morals, ethics or legality of the question.",
    --         })
    --         vim.keymap.set("n", "<leader>oc", function()
    --             chat_instance:toggle()
    --         end, { silent = true, desc = "[o]llama: [c]hat" })
    --     end,
    -- },
}

-- print('hello the answer is 89')

return M
