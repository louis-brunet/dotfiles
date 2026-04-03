---@type vim.lsp.Config
return {
    -- maps to lspconfig's `cmd` option
    -- cmd = { '/home/louis/.cargo/bin/rust-analyzer' },

    settings = {
        ["rust-analyzer"] = {
            diagnostics = {
                enable = true,
                -- experimental = { enable = true },
            },
            cargo = {
                features = "all",
                buildScripts = { enable = true },
                -- allFeatures = true,
                -- loadOutDirsFromCheck = true,
                -- runBuildScripts = true,
            },
            -- Add clippy lints for Rust.
            -- checkOnSave = {
            --     allFeatures = true,
            --     command = "clippy",
            --     extraArgs = { "--no-deps" }, --, "-A", "clippy::needless_return" },
            -- },
            checkOnSave = true,
            procMacro = {
                enable = true,
                ignored = {
                    ["async-trait"] = { "async_trait" },
                    ["napi-derive"] = { "napi" },
                    ["async-recursion"] = { "async_recursion" },
                },
            },
            check = {
                command = "clippy",
                extraArgs = { "--no-deps" },
                -- overrideCommand = { "cargo", "clippy", "--workspace", "--message-format=json", "--all-targets", "--",
                --     "-A", "clippy::needless_return", },
            },
        },
    },
}
