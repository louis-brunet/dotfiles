---@type LazySpec
return {
    "rest-nvim/rest.nvim", -- https://github.com/rest-nvim/rest.nvim
    dependencies = {
        { "nvim-lua/plenary.nvim" },
    },

    -- ft = { 'http' },

    keys = {
        { '<leader>rq', function() require('rest-nvim').run() end, buffer = true, desc = '[r]est-nvim re[q]uest' },
        { '<leader>rp', '<Plug>RestNvimPreview',                   buffer = true, desc = '[r]est-nvim [p]review' },
    },

    opts = {
        -- Open request results in a horizontal split
        result_split_horizontal = false,

        -- Keep the http file buffer above|left when split horizontal|vertical
        result_split_in_place = false,

        -- stay in current windows (.http file) or change to results window (default)
        stay_in_current_window_after_split = false,

        -- Skip SSL verification, useful for unknown certificates
        skip_ssl_verification = false,

        -- Encode URL before making request
        encode_url = true,

        -- Highlight request on run
        highlight = {
            enabled = true,
            timeout = 150,
        },

        result = {
            -- toggle showing URL, HTTP info, headers at top the of result window
            show_url = true,

            -- show the generated curl command in case you want to launch
            -- the same request via the terminal (can be verbose)
            show_curl_command = true,

            show_http_info = true,

            show_headers = true,

            -- table of curl `--write-out` variables or false if disabled
            -- for more granular control see Statistics Spec
            show_statistics = false,

            -- executables or functions for formatting response body [optional]
            -- set them to false if you want to disable them
            formatters = {
                -- json = "jq",
                -- html = function(body)
                --     return vim.fn.system({ "tidy", "-i", "-q", "-" }, body)
                -- end
            },
        },

        -- Jump to request line on run
        jump_to_request = false,

        env_file = '.env',

        -- for telescope select
        env_pattern = "\\.env$",

        env_edit_command = "tabedit",

        custom_dynamic_variables = {},

        yank_dry_run = true,

        search_back = true,
    },

    config = function(_, opts)
        -- available keymaps (rhs of vim.keymap.set(mode, lhs, rhs, ...)):
        --   <Plug>RestNvim         : run HTTP request under cursor (in .http file)
        --      (same as require(rest-nvim').run())
        --   <Plug>RestNvimPreview  : preview underlying cURL command
        --   <Plug>RestNvimLast     : rerun last HTTP request

        local rest_nvim = require('rest-nvim')
        rest_nvim.setup(opts)
    end,
}
