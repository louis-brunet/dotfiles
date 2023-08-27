-- vim.api.nvim_create_user_command('TransparentToggle', function()
--     local onedark = require 'onedark'
--     onedark.setup {
--         transparent = not vim.g.onedark_config.transparent,
--         highlights = {
--             TreesitterContextBottom = {fmt="underline", sp="Grey"},
--
--         },
--     }
--     onedark.load()
-- end, { desc = "Toggle transparent background" })

vim.api.nvim_create_user_command('ShadeToggle', function()
    local shade = require 'shade'
    shade.toggle()
end, { desc = "Toggle shade plugin" })
