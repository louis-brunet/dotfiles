---@type LazySpec
return {
    'rcarriga/nvim-notify',

    event = 'VeryLazy',

    ---@type notify.Config
    opts = {
        fps = 60,
        stages = 'slide',
        timeout = 1500, -- milliseconds

        -- DEFAULTS:
        -- background_colour = "NotifyBackground",
        -- fps = 30,
        -- icons = {
        --   DEBUG = "",
        --   ERROR = "",
        --   INFO = "",
        --   TRACE = "✎",
        --   WARN = ""
        -- },
        -- level = 2,
        -- minimum_width = 50,
        -- render = "default",
        -- stages = "fade_in_slide_out",
        -- time_formats = {
        --   notification = "%T",
        --   notification_history = "%FT%T"
        -- },
        -- timeout = 5000,
        -- top_down = true
    },

    config = function(_, opts)
        local nvim_notify = require('notify')
        nvim_notify.setup(opts)

        vim.notify = function(msg, level, notify_opts)
            notify_opts = notify_opts or {}
            notify_opts.animate = false -- turn off the first stage of animation, start timeout immediately

            nvim_notify(msg, level, notify_opts)
        end

        local has_which_key, which_key = pcall(require, 'which-key')
        if has_which_key then
            which_key.add({
                { "<leader>n", group = "[n]otify" },
            })
        end
        vim.keymap.set(
            "n", "<leader>nd",
            nvim_notify.dismiss,
            { desc = "[d]ismiss notifications" }
        )
        vim.keymap.set(
            "n", "<leader>ns",
            require("telescope").extensions.notify.notify,
            { desc = "[s]earch notifications" }
        )
    end
}
