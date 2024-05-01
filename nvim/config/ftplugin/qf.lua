vim.keymap.set(
    'n',
    '<leader>qd',
    function()
        require('user.utils.quickfix').delete_quickfix_current_line({ confirm = false })
    end,
    { desc = '[q]uickfix: [d]elete current line', buffer = 0 }
)
vim.keymap.set(
    'x',
    '<leader>qd',
    function()
        require('user.utils.quickfix').delete_quickfix_visual({ confirm = false })
    end,
    { desc = '[q]uickfix: [d]elete selected lines', buffer = 0 }
)
