-- [[ ensure DAP servers are installed ]]
---@type LazySpec
return {
    -- mason.nvim integration
    {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = "mason.nvim",
        -- cmd = { "DapInstall", "DapUninstall" },
        opts = {
            -- Makes a best effort to setup the various debuggers with
            -- reasonable debug configurations
            automatic_installation = true,

            -- additional configuration for the handlers,
            -- see mason-nvim-dap README for more information
            handlers = {},

            -- :h mason-nvim-dap.nvim-available-dap-adapters
            -- https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua
            ensure_installed = require('user.config.dap').mason_nvim_dap_ensure_installed,
        },
    },
}
