---@type LazySpec
return {
    'rcarriga/nvim-notify',

    event = 'VeryLazy',

    ---@type notify.Config
    opts = {
        fps = 60,

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
        vim.notify = require('notify')
    end
}
