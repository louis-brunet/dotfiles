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
    cmd = user_dap_config.dap_cmd,
    keys = user_dap_config.dap_keys,
    config = user_dap_config.dap_config,
}

return M
