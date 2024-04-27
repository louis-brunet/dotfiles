---@type HarpoonToggleOptions
local harpoon_ui_config = {
    -- border? any this value is directly passed to nvim_open_win
    -- title? string this value is directly passed to nvim_open_win
    -- ui_fallback_width? number used if we can't get the current window

    -- this value is directly passed to nvim_open_win
    title_pos = 'center',

    -- this is the ratio of the editor window to use
    ui_width_ratio = 0.9,

    -- number this is the max width the window can be
    ui_max_width = 69,
}


---@type LazySpec
return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    ---@type HarpoonPartialConfig
    opts = {
        -- settings = {
        --     -- key
        --     -- save_on_toggle
        --     -- sync_on_ui_close
        -- },

        -- ---@type HarpoonPartialConfigItem
        -- default = {
        -- },

        -- ---@type HarpoonPartialConfigItem
        -- my_custom_list = {
        -- },
    },
    keys = {
        {
            "<leader>Ha",
            function()
                require("harpoon"):list():add()
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
        -- {
        --     "<C-Shift-n>",
        --     function()
        --         require("harpoon"):list():next({ ui_nav_wrap = true })
        --     end,
        --     desc = "Harpoon next file",
        -- },
        {
            "<leader>Hp",
            function()
                require("harpoon"):list():prev({ ui_nav_wrap = true })
            end,
            desc = "Harpoon previous file",
        },
        -- {
        --     "<C-Shift-p>",
        --     function()
        --         require("harpoon"):list():prev({ ui_nav_wrap = true })
        --     end,
        --     desc = "Harpoon previous file",
        -- },
        {
            "<leader>h",
            function()
                local harpoon = require("harpoon")
                harpoon.ui:toggle_quick_menu(harpoon:list(), harpoon_ui_config)
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

    ---@param opts HarpoonPartialConfig
    config = function(_, opts)
        local harpoon = require('harpoon')
        local harpoon_builtins = require('harpoon.extensions').builtins

        harpoon:setup(opts)
        harpoon:extend(harpoon_builtins.navigate_with_number())
        -- harpoon:extend({
        --     UI_CREATE = function(cx)
        --         -- vim.keymap.set("n", "<C-v>", function()
        --         --     harpoon.ui:select_menu_item({ vsplit = true })
        --         -- end, { buffer = cx.bufnr })
        --         --
        --         -- vim.keymap.set("n", "<C-x>", function()
        --         --     harpoon.ui:select_menu_item({ split = true })
        --         -- end, { buffer = cx.bufnr })
        --         --
        --         -- vim.keymap.set("n", "<C-t>", function()
        --         --     harpoon.ui:select_menu_item({ tabedit = true })
        --         -- end, { buffer = cx.bufnr })
        --     end,
        -- })
    end
}
