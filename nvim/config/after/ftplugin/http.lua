local rest_nvim = require('rest-nvim')
-- local wk = require('which-key')

vim.keymap.set('n', '<leader>rq', rest_nvim.run, { buffer = true, desc = '[R]estNvim re[q]uest' })
vim.keymap.set('n', '<leader>rp', '<Plug>RestNvimPreview', { buffer = true, desc = '[R]estNvim [p]review' })

-- FIXME: can't get group prefix to show up in which-key window (it shows up on 
-- the line below **after** the prefix is pressed, the desc displayed is still "+prefix")
--
-- wk.register({
--     ['<leader>r'] = {
--         name = '+[R]estNvim',
--         q = { rest_nvim.run, '[R]estNvim re[q]uest', buffer = 0 },
--         p = { rest_nvim.run, '[R]estNvim Preview', buffer = 0 },
--     }
-- })


