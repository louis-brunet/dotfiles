---@type LazySpec
return {
    'rcarriga/nvim-notify',

    event = 'VeryLazy',

    ---@type notify.Config
    opts = {
        fps = 60,
        stages = 'fade'

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
        vim.notify = nvim_notify
    end
}
