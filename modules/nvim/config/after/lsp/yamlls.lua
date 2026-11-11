---@type vim.lsp.Config
return {
    on_attach = {
        function(client, _)
            client.server_capabilities.documentFormattingProvider = true
        end,
    },
    -- https://github.com/redhat-developer/yaml-language-server?tab=readme-ov-file#language-server-settings
    settings = {
        redhat = { telemetry = { enabled = false } },
        yaml = {
            schemas = {
                -- ["https://json.schemastore.org/github-workflow.json"] = {
                --     ".github/workflows/*.{yaml,yml}",
                -- },
                -- ["https://json.schemastore.org/github-action.json"] = {
                --     ".github/actions/*.{yaml,yml}",
                --     "action.{yaml,yml}"
                -- },
                ["https://raw.githubusercontent.com/canonical/cloud-init/refs/heads/main/cloudinit/config/schemas/schema-cloud-config-v1.json"] =
                "*cloud-config.{yaml,yml}",
            },
            format = { enable = true, singleQuote = true, printWidth = 80 },
        },
    },
}
