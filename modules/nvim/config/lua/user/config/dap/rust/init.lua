local function config_rust()
    local dap_config_utils = require('user.config.dap.utils')
    local adapter_key = "rust_codelldb";
    dap_config_utils.set_adapter_if_not_defined(adapter_key, {
        type = "server",
        port = "${port}",
        host = "127.0.0.1",
        executable = {
            command = vim.fn.exepath("codelldb"),
            args = {
                -- '--liblldb', liblldb_path,
                "--port",
                "${port}",
            },
        },
    })

    dap_config_utils.set_configs_if_not_defined("rust", {
        -- {
        --     type = adapter_key,
        --     request = 'launch',
        --     name = 'TODO: this config (Launch file or smth)',
        --     -- program = '${file}',
        --     cwd = '${workspaceFolder}',
        --     -- args = opts.executable_args or {},
        --     -- console = 'integratedTerminal',
        -- },

        {
            name = "TODO: config?",
            type = adapter_key,
            request = "launch",
            cargo = {
                args = { "test", "--no-run", "--lib", "--bin" },  -- Cargo command line to build the debug target
                -- args = { 'build' }, --, "--bin=foo"] is another possibility

                -- The rest are optional
                -- env = { RUSTFLAGS = '-Clinker=ld.mold' }, -- Extra environment variables.
                -- problemMatcher = "$rustc",        -- Problem matcher(s) to apply to cargo output.
                -- filter = {                                 -- Filter applied to compilation artifacts.
                --     name = "mylib",
                --     kind = "lib"
                -- }
            },
            cwd = "${workspaceFolder}",
            -- program = '${workspaceFolder}/target/debug/${file}',
            program = function()
                return vim.fn.input("Path to executable: ",
                    vim.fn.getcwd() .. "/target/debug/", "file")
            end,
            stopOnEntry = false,
        },
    })
end


---@type UserDapConfigLanguageModule
local M = {
    configure = config_rust,
}
return M
