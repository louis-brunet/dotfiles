vim.api.nvim_create_user_command("TypescriptExecutePackageJsonScript", function()
    require("user.utils.javascript").run_package_json_script({})
end, {
    desc = "Execute package.json script",
    -- group = vim.api.nvim_create_augroup(
    -- "autocmd_TypescriptExecutePackageJsonScript", {
    --     clear = true
    -- }),
    -- callback = function(_)
    --     require('user.utils.javascript').run_package_json_script({})
    -- end,
})
vim.keymap.set("n", "<leader>ts",
    function() vim.cmd("TypescriptExecutePackageJsonScript") end,
    { desc = "[t]ypescript run package.json [s]cript", })

vim.api.nvim_create_user_command("TypescriptPackageJsonOpen", function()
    require("user.utils.javascript").open_package_json()
end, {
    desc = "Open package.json",
})
vim.keymap.set("n", "<leader>tp",
    function() vim.cmd("TypescriptPackageJsonOpen") end,
    { desc = "[t]ypescript open [p]ackage.json", })
