---@type LazySpec
return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    ---@type HarpoonPartialConfigItem
    opts = {
        menu = {
            width = vim.api.nvim_win_get_width(0) - 4,
        },
    },
    keys = {
        {
            "<leader>Ha",
            function()
                require("harpoon"):list():append()
            end,
            desc = "Harpoon file add",
        },
        {
            "<leader>Hn",
            function()
                require("harpoon"):list():next({ ui_nav_wrap = true })
            end,
            desc = "Harpoon next file",
        },
        { "<leader>Hp",
            function()
                require("harpoon"):list():prev({ ui_nav_wrap = true })
            end,
            desc = "Harpoon previous file",
        },
        {
            "<leader>h",
            function()
                local harpoon = require("harpoon")
                harpoon.ui:toggle_quick_menu(harpoon:list(), {
                    -- border? any this value is directly passed to nvim_open_win
                    -- title_pos? any this value is directly passed to nvim_open_win
                    -- title? string this value is directly passed to nvim_open_win
                    -- ui_fallback_width? number used if we can't get the current window

                    -- this is the ratio of the editor window to use
                    ui_width_ratio = 0.9,

                    -- number this is the max width the window can be
                    ui_max_width = 69,
                })
            end,
            desc = "Harpoon quick menu",
        },
        {
            "<leader>&",
            function()
                require("harpoon"):list():select(1)
            end,
            desc = "Harpoon to file 1",
        },
        {
            "<leader>é",
            function()
                require("harpoon"):list():select(2)
            end,
            desc = "Harpoon to file 2",
        },
        {
            [[<leader>"]],
            function()
                require("harpoon"):list():select(3)
            end,
            desc = "Harpoon to file 3",
        },
        {
            "<leader>'",
            function()
                require("harpoon"):list():select(4)
            end,
            desc = "Harpoon to file 4",
        },
        {
            "<leader>(",
            function()
                require("harpoon"):list():select(5)
            end,
            desc = "Harpoon to file 5",
        },
    },
}
