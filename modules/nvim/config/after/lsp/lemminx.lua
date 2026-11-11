local function get_user_cache_dir()
    local cache_home = vim.env.XDG_CACHE_HOME
    if not cache_home or cache_home == "" then
        cache_home = vim.fs.joinpath(vim.fn.expand("~"), ".cache")
    end
    return cache_home
end

---@type vim.lsp.Config
return {
    settings = {
        -- https://github.com/eclipse-lemminx/lemminx/blob/main/docs/Configuration.md#settings
        -- NOTE: Additional settings mentioned here:
        --   - coc-xml: https://github.com/fannheyward/coc-xml?tab=readme-ov-file#supported-settings
        --   - vscode-xml: https://github.com/redhat-developer/vscode-xml?tab=readme-ov-file#supported-vs-code-settings
        xml = {
            -- https://github.com/redhat-developer/vscode-xml/blob/main/docs/Formatting.md
            format = {
                enabled = true,
                -- preserve, splitNewLine, alignWithFirstAttr
                splitAttributes = "splitNewLine",
                splitAttributesIndentSize = 2,
                spaceBeforeEmptyCloseTag = true,
                preserveAttributeLineBreaks = true,  -- can be overriden by splitAttributes
                closingBracketNewLine = false,
                maxLineWidth = 80,
            },
            logs = {
                client = true,
                -- file = ...
            },
            fileAssociations = {
                -- {
                --     systemId =
                --     "https://raw.githubusercontent.com/apigee/api-platform-samples/refs/heads/master/schemas/policy/assign_message.xsd",
                --     pattern = "AM-*.xml",
                -- }
                -- example:
                -- {
                --     systemId =
                --     "C:\\org.eclipse.lsp4xml\\src\\test\\resources\\xsd\\projectDescription.xsd",
                --     pattern = ".project",
                -- }
            },
            --
            server = {
                workDir = vim.fs.joinpath(get_user_cache_dir(), "lemminx"),
                -- FIXME: cannot download schemas because of Netskope
                -- proxy's self-signed cert, not recognized by
                -- Java/by the compiled lemminx binary.
                -- Should probably try to install JRE and lemminx externally
                -- to fix these issues
                --
                -- binary = { args = "-Djava.net.useSystemProxies=true" },
                -- binary = { args = "-Djavax.net.ssl.trustStore='/Library/Application Support/Netskope/STAgent/data/nscacert.pem'" },
                -- vmargs = '-Djava.net.useSystemProxies=true',
                -- vmargs = '-Dhttp.proxyHost=gateway-par1.goskope.com',
                -- vmargs = "-Djavax.net.ssl.trustStore='/Library/Application Support/Netskope/STAgent/data/nscacert.pem'",
            },
        },
    },
}
