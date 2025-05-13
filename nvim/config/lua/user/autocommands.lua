-- [[ Highlight on yank ]]
-- See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        -- NOTE: vim.highlight was renamed to vim.hl in v0.11
        local hl = vim.hl or vim.highlight
        hl.on_yank({})
    end,
    group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
    pattern = "*",
})

