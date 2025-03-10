---https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
---@class OllamaApiGenerateRequestBodyModelfileOptions
---@field mirostat? number Enable Mirostat sampling for controlling perplexity. (default: 0, 0 = disabled, 1 = Mirostat, 2 = Mirostat 2.0)
---@field mirostat_eta? number Influences how quickly the algorithm responds to feedback from the generated text. A lower learning rate will result in slower adjustments, while a higher learning rate will make the algorithm more responsive. (Default: 0.1)
---@field mirostat_tau? number Controls the balance between coherence and diversity of the output. A lower value will result in more focused and coherent text. (Default: 5.0)
---@field num_ctx? number Sets the size of the context window used to generate the next token. (Default: 2048)
---@field repeat_last_n? number Sets how far back for the model to look back to prevent repetition. (Default: 64, 0 = disabled, -1 = num_ctx)
---@field repeat_penalty? number Sets how strongly to penalize repetitions. A higher value (e.g., 1.5) will penalize repetitions more strongly, while a lower value (e.g., 0.9) will be more lenient. (Default: 1.1)
---@field temperature? number The temperature of the model. Increasing the temperature will make the model answer more creatively. (Default: 0.8)
---@field seed? number Sets the random number seed to use for generation. Setting this to a specific number will make the model generate the same text for the same prompt. (Default: 0)
---@field stop? string[] Sets the stop sequences to use. When this pattern is encountered the LLM will stop generating text and return. Multiple stop patterns may be set by specifying multiple separate stop parameters in a modelfile.
---@field tfs_z? number Tail free sampling is used to reduce the impact of less probable tokens from the output. A higher value (e.g., 2.0) will reduce the impact more, while a value of 1.0 disables this setting. (default: 1)
---@field num_predict? number Maximum number of tokens to predict when generating text. (Default: 128, -1 = infinite generation, -2 = fill context)
---@field top_k? number Reduces the probability of generating nonsense. A higher value (e.g. 100) will give more diverse answers, while a lower value (e.g. 10) will be more conservative. (Default: 40)
---@field top_p? number Works together with top-k. A higher value (e.g., 0.95) will lead to more diverse text, while a lower value (e.g., 0.5) will generate more focused and conservative text. (Default: 0.9)
---@field min_p? number Alternative to the top_p, and aims to ensure a balance of quality and variety. The parameter p represents the minimum probability for a token to be considered, relative to the probability of the most likely token. For example, with p=0.05 and the most likely token having a probability of 0.9, logits with a value less than 0.045 are filtered out. (Default: 0.0)

---https://github.com/ollama/ollama/blob/main/docs/api.md#parameters
---@class OllamaApiGenerateRequestBody
---@field model? string
---@field prompt? string
---@field suffix? string
---@field images? string[]
---@field raw? boolean
---@field stream? boolean
---@field format? "json"
---@field system? string
---@field template? string
---@field keep_alive? string default is "5m"
---@field options? OllamaApiGenerateRequestBodyModelfileOptions

---https://github.com/ollama/ollama/blob/main/docs/api.md#parameters
---@class OpenAiApiGenerateRequestBody
---@field model? string
---@field prompt? string
---@field temperature? number Defaults to 1 - What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.
---@field max_tokens? number Defaults to 16 - The maximum number of tokens that can be generated in the completion.
---@field stop? string|string[]
---@field stream? boolean
---@field suffix? string

---https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md#post-completion-given-a-prompt-it-returns-the-predicted-completion
---@class LlamacppApiGenerateRequestBody
---@field prompt? string|string[] Provide the prompt for this completion as a string or as an array of strings or numbers representing tokens. Internally, if `cache_prompt` is `true`, the prompt is compared to the previous completion and only the "unseen" suffix is evaluated. A `BOS` token is inserted at the start, if all of the following conditions are true: - The prompt is a string or an array with the first element given as a string; - The model's `tokenizer.ggml.add_bos_token` metadata is `true`
---@field temperature? number Adjust the randomness of the generated text. Default: `0.8`
---@field dynatemp_range? number Dynamic temperature range. The final temperature will be in the range of `[temperature - dynatemp_range; temperature + dynatemp_range]` Default: `0.0`, which is disabled.
---@field dynatemp_exponent? number Dynamic temperature exponent. Default: `1.0`
---@field top_k? integer Limit the next token selection to the K most probable tokens.  Default: `40`
---@field top_p? number Limit the next token selection to a subset of tokens with a cumulative probability above a threshold P. Default: `0.95`
---@field min_p? number The minimum probability for a token to be considered, relative to the probability of the most likely token. Default: `0.05`
---@field n_predict? number Set the maximum number of tokens to predict when generating text. **Note:** May exceed the set limit slightly if the last token is a partial multibyte character. When 0, no tokens will be generated but the prompt is evaluated into the cache. Default: `-1`, where `-1` is infinity.
---@field n_indent? number Specify the minimum line indentation for the generated text in number of whitespace characters. Useful for code completion tasks. Default: `0`
---@field n_keep? number Specify the number of tokens from the prompt to retain when the context size is exceeded and tokens need to be discarded. The number excludes the BOS token. By default, this value is set to `0`, meaning no tokens are kept. Use `-1` to retain all tokens from the prompt.
---@field stream? boolean It allows receiving each predicted token in real-time instead of waiting for the completion to finish. To enable this, set to `true`.
---@field stop? string[] Specify a JSON array of stopping strings. These words will not be included in the completion, so make sure to add them to the prompt for the next iteration. Default: `[]`
---@field tfs_z? number Enable tail free sampling with parameter z. Default: `1.0`, which is disabled.
---@field typical_p? number Enable locally typical sampling with parameter p. Default: `1.0`, which is disabled.
---@field repeat_penalty? number Control the repetition of token sequences in the generated text. Default: `1.1`
---@field repeat_last_n? number Last n tokens to consider for penalizing repetition. Default: `64`, where `0` is disabled and `-1` is ctx-size.
---@field penalize_nl? boolean Penalize newline tokens when applying the repeat penalty. Default: `true`
---@field presence_penalty? number Repeat alpha presence penalty. Default: `0.0`, which is disabled.
---@field frequency_penalty? number Repeat alpha frequency penalty. Default: `0.0`, which is disabled.
---@field mirostat? number Enable Mirostat sampling, controlling perplexity during text generation. Default: `0`, where `0` is disabled, `1` is Mirostat, and `2` is Mirostat 2.0.
---@field mirostat_tau? number Set the Mirostat target entropy, parameter tau. Default: `5.0`
---@field mirostat_eta? number Set the Mirostat learning rate, parameter eta.  Default: `0.1`
---@field grammar? string Set grammar for grammar-based sampling.  Default: no grammar
---@field json_schema? string Set a JSON schema for grammar-based sampling (e.g. `{"items": {"type": "string"}, "minItems": 10, "maxItems": 100}` of a list of strings, or `{}` for any JSON). See [tests](../../tests/test-json-schema-to-grammar.cpp) for supported features.  Default: no JSON schema.
---@field seed? number Set the random number generator (RNG) seed.  Default: `-1`, which is a random seed.
---@field ignore_eos? boolean Ignore end of stream token and continue generating.  Default: `false`
---@field logit_bias? table<table>  Modify the likelihood of a token appearing in the generated text completion. For example, use `"logit_bias": [[15043,1.0]]` to increase the likelihood of the token 'Hello', or `"logit_bias": [[15043,-1.0]]` to decrease its likelihood. Setting the value to false, `"logit_bias": [[15043,false]]` ensures that the token `Hello` is never produced. The tokens can also be represented as strings, e.g. `[["Hello, World!",-0.5]]` will reduce the likelihood of all the individual tokens that represent the string `Hello, World!`, just like the `presence_penalty` does. Default: `[]`
---@field n_probs? number If greater than 0, the response also contains the probabilities of top N tokens for each generated token given the sampling settings. Note that for temperature < 0 the tokens are sampled greedily but token probabilities are still being calculated via a simple softmax of the logits without considering any other sampler settings. Default: `0`
---@field min_keep? number If greater than 0, force samplers to return N possible tokens at minimum. Default: `0`
---@field t_max_predict_ms? number Set a time limit in milliseconds for the prediction (a.k.a. text-generation) phase. The timeout will trigger if the generation takes more than the specified time (measured since the first token was generated) and if a new-line character has already been generated. Useful for FIM applications. Default: `0`, which is disabled.
---@field image_data? string[] An array of objects to hold base64-encoded image `data` and its `id`s to be reference in `prompt`. You can determine the place of the image in the prompt as in the following: `USER:[img-12]Describe the image in detail.\nASSISTANT:`. In this case, `[img-12]` will be replaced by the embeddings of the image with id `12` in the following `image_data` array: `{..., "image_data": [{"data": "<BASE64_STRING>", "id": 12}]}`. Use `image_data` only with multimodal models, e.g., LLaVA.
---@field id_slot? number Assign the completion task to an specific slot. If is -1 the task will be assigned to a Idle slot.  Default: `-1`
---@field cache_prompt? boolean Re-use KV cache from a previous request if possible. This way the common prefix does not have to be re-processed, only the suffix that differs between the requests. Because (depending on the backend) the logits are **not** guaranteed to be bit-for-bit identical for different batch sizes (prompt processing vs. token generation) enabling this option can cause nondeterministic results. Default: `false`
---@field samplers? string[] The order the samplers should be applied in. An array of strings representing sampler type names. If a sampler is not set, it will not be used. If a sampler is specified more than once, it will be applied multiple times. Default: `["top_k", "tfs_z", "typical_p", "top_p", "min_p", "temperature"]` - these are all the available values.

---@type LazySpec
local M = {

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


    -- Import Lazy specs in lua/user/lazy-spec/ai/*.lua (except init.lua)
    { import = 'user.lazy-spec.ai' },
}

return M
