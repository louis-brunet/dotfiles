--- :h event-args
---@class VimAucmdCallbackEvent
---@field id number autocommand id
---@field event string name of the triggered event
---@field group number|nil autocommand group id, if any
---@field match string expanded value of <amatch>
---@field buf number expanded value of <abuf>
---@field file string expanded value of <afile>
---@field data any arbitrary data passed from


---@type table<string, fun(opts: VimAucmdCallbackEvent):nil>
local ft_handlers = {
    qf = function(opts)
        opts = opts or {}
        if opts.buf == nil then
            opts.buf = 0
        end
        vim.keymap.set(
            'n',
            '<leader>qd',
            function()
                require('user.utils.quickfix').delete_quickfix_current_line({ confirm = false })
            end,
            { desc = '[q]uickfix: [d]elete current line', buffer = opts.buf }
        )
        vim.keymap.set(
            'x',
            '<leader>qd',
            function()
                require('user.utils.quickfix').delete_quickfix_visual({ confirm = false })
            end,
            { desc = '[q]uickfix: [d]elete selected lines', buffer = opts.buf }
        )
    end,
}

local ft_options = {
    gitcommit = { spell = true, wrap = true },
    markdown = { spell = true, wrap = true },
    tex = { spell = true, wrap = true },
    ['terraform-vars'] = { commentstring = '#%s' },
}

local function setup_filetype_options()
    for filetype, options in pairs(ft_options) do
        vim.api.nvim_create_autocmd('FileType', {
            desc = 'Configure buffer options for filetype ' .. filetype,

            pattern = filetype,
            group = vim.api.nvim_create_augroup('FileType_options_' .. filetype, { clear = true }),
            callback = function(_)
                for option_name, option_value in pairs(options) do
                    vim.api.nvim_set_option_value(option_name, option_value, { scope = 'local' })
                end
            end,
        })
    end

    for filetype, handler in pairs(ft_handlers) do
        vim.api.nvim_create_autocmd('FileType', {
            desc = 'Execute configuration handler for buffer with filetype ' .. filetype,

            pattern = filetype,
            group = vim.api.nvim_create_augroup('FileType_handler_' .. filetype, { clear = true }),
            callback = function(_)
                handler()
            end,
        })
    end
end

setup_filetype_options()
