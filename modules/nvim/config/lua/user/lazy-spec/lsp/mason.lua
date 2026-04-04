local custom_mason_config = {
    ensure_installed = {
        "hadolint",

        -- NOTE: alphatab-languages-server is a custom entry declared in
        -- ./mason/custom-registry/
        -- "alphatab-language-server",
    },
}

---@type LazySpec
return {
    -- Automatically install LSPs to stdpath for neovim
    { "mason-org/mason.nvim", cmd = "Mason", config = true },

    "mason-org/mason-lspconfig.nvim",

    -- Install extra tools from mason registry
    {
        "mason-org/mason.nvim",
        ---@type MasonSettings
        opts = {
            registries = {
                "github:mason-org/mason-registry",
                "lua:user.lazy-spec.lsp.mason.custom-registry",
            },
        },
        config = function(_, opts)
            require("mason").setup(opts)
            local registry = require("mason-registry")

            local function notify(message)
                vim.notify(
                    message, vim.log.levels.INFO,
                    { title = "Custom mason installer" }
                )
            end

            -- Normal registry packages + injected custom ones all handled the same way
            registry.refresh(function()
                for _, name in ipairs(custom_mason_config.ensure_installed) do
                    local pkg = registry.get_package(name)
                    if not pkg:is_installed() then
                        pkg:install()
                        notify("Installed " .. name .. " from mason registry.")
                    end
                end
            end)
        end,
    },
}
