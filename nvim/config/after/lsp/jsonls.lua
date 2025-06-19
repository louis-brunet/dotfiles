---@type vim.lsp.Config
return {
    settings = {
        json = {
            validate = { enable = true },
            schemas = {
                {
                    fileMatch = "package.json",
                    url = "https://json.schemastore.org/package.json",
                },
                {
                    fileMatch = { "tsconfig.json", "tsconfig.*.json" },
                    url = "https://json.schemastore.org/tsconfig",
                },
                {
                    fileMatch = "pyrightconfig.json",
                    url =
                    "https://raw.githubusercontent.com/microsoft/pyright/main/packages/vscode-pyright/schemas/pyrightconfig.schema.json",
                },
                {
                    fileMatch = { "opencode.json", "opencode.jsonc" },
                    url = "https://opencode.ai/config.json",
                },
                -- {
                --     fileMatch = "nest-cli.json",
                --     url = "https://json.schemastore.org/nest-cli"
                -- },
            },
        },
    },
}
