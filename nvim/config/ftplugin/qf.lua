vim.keymap.set(
    'n',
    '<leader>qd',
    function()
        local current_line = vim.api.nvim_win_get_cursor(0)[1]
        local CHOICES = { yes = 'Yes', no = 'No' }

        vim.ui.select(
            { CHOICES.no, CHOICES.yes },
            {
                prompts = 'Delete quickfix item at line ' .. current_line .. '?',
                -- format_item = function(item) return 'toto'..item end,
            },
            function(chosen_item)
                if chosen_item == CHOICES.yes then
                    require('user.utils.quickfix').delete_quickfix_item(current_line)
                    vim.notify('Deleted quickfix item', vim.log.levels.INFO, { title = '' })
                elseif chosen_item == CHOICES.no then

                else
                    error('todo')
                end
            end
        )
    end,
    { desc = '', buffer = 0 }
)
