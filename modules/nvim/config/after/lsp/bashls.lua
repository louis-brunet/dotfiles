-- NOTE: also run `:MasonInstall shellcheck` and `:MasonInstall shfmt` for
-- more features

---@type vim.lsp.Config
return {
    filetypes = {
        "zsh",
        "bash",

        -- default filetypes
        "sh",
    },
}
