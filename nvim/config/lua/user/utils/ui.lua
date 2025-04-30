local M = {}

---@param prompt string
---@param callbacks { on_accept: fun():nil; on_deny: nil|fun():nil }
---@param opts? { choices?: { yes: string, no: string }|nil }|nil
function M.ui_confirm(prompt, callbacks, opts)
    opts = opts or {}
    local choices = opts.choices or { yes = "Yes", no = "No" }
    assert(choices.yes ~= choices.no)

    vim.ui.select(
        { choices.no, choices.yes },
        { prompt = prompt, },
        function(chosen_item)
            if chosen_item == choices.yes then
                callbacks.on_accept()
            else
                if type(callbacks.on_deny) == "function" then
                    callbacks.on_deny()
                end
                return
            end
        end
    )
end

return M
