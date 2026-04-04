---@type vim.lsp.Config
return {
    cmd = {
        "node",
        vim.fn.stdpath("data") ..
        "/mason/packages/alphatab-language-server/node_modules/@coderline/alphatab-language-server/dist/server.mjs",
    },
    -- cmd = {
    --     "node",
    --     vim.fn.stdpath("data") .. "/mason/packages/alphatab-language-server/dist/server.mjs",
    --     "--stdio"
    -- },
    filetypes = { "alphatex" },
    root_dir = function(fname)
        return vim.fs.root(fname, { ".git" }) or vim.fn.getcwd()
    end,
    single_file_support = true,
}
