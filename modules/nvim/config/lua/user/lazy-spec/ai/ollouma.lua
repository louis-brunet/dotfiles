---@type LazySpec
local M = {

    -- {
    --     -- TODO: change to louis-brunet/ollouma.nvim
    --     dir = '/home/louis/code/ollouma.nvim',
    --
    --     event = 'VeryLazy',
    --
    --     keys = {
    --         { "<leader>ot", ":Telescope ollouma ", desc = "[o]llouma: [t]elescope" },
    --         { "<leader>or", function() require('ollouma').resume_session() end, desc = "[o]llouma: [r]esume session" },
    --         { "<leader>oe", function() require('ollouma').exit_session() end, desc = "[o]llouma: [e]xit session" },
    --         { "<leader>oo", ':Ollouma select_action<CR>', desc = "[o]llouma select action" },
    --         { "<leader>o", ':Ollouma select_action<CR>', desc = "[o]llouma", mode = 'x' },
    --     },
    --
    --     dependencies = {
    --         {
    --             'nvim-telescope/telescope.nvim',
    --             -- config = function (_, opts)
    --             --     local telescope = require('telescope')
    --             --     telescope.setup(opts)
    --             --     telescope.register_extension('ollouma')
    --             -- end
    --         }
    --
    --     },
    --
    --     ---@type OlloumaPartialConfig
    --     opts = {
    --         model = 'llama3',
    --         -- model_actions = {
    --         --     {
    --         --         name = 'test from lazy spec',
    --         --         on_select = function (current_model)
    --         --             vim.notify('Hi from lazy spec, current_model is '..current_model)
    --         --         end
    --         --     }
    --         -- },
    --     },
    --
    --     -- config = function (_, opts)
    --     --     require('ollouma').setup(opts)
    --     -- end
    -- },

}
return M
