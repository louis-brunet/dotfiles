-- [[ Configure DAP (Debug Adapter Protocol) ]]

local user_dap_config = require('user.config.dap');

---@type LazySpec
local M = {
    'mfussenegger/nvim-dap',

    -- event = 'VeryLazy',

    dependencies = {
        -- DAP dependencies in lua/user/plugins/dap/*.lua (except init.lua)
        { import = 'user.plugins.dap' },
    },

    keys = user_dap_config.dap_keys,

    config = user_dap_config.config_dap,
}

return M
