---@alias OlloumaDevReloadablePlugin "ollouma"|"telescope.nvim"



local M = {}


---@param plugins? OlloumaDevReloadablePlugin[]
function M.reload_plugins(plugins)
    require('ollouma.util.ui'):close()
    plugins = plugins or { 'ollouma', 'telescope.nvim' }

    for _, plugin in ipairs(plugins) do
        vim.cmd('Lazy reload ' .. plugin)
        vim.notify('Reloaded plugin ' .. plugin, vim.log.levels.INFO)
    end

end

return M

