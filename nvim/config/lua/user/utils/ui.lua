local M = {}

---@param prompt string
---@param callbacks { on_accept: fun():nil; on_deny: nil|fun():nil }
function M.ui_confirm(prompt, callbacks)
    local CHOICES = { yes = 'Yes', no = 'No' }

    vim.ui.select(
        { CHOICES.no, CHOICES.yes },
        {
            prompt = prompt,
        },
        function(chosen_item)
            if chosen_item == CHOICES.yes then
                callbacks.on_accept()
            else
                if type(callbacks.on_deny) =='function' then
                    callbacks.on_deny()
                end
                return
            end
        end
    )
end

return M
