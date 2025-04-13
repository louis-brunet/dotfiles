--- [ Git related plugins ]
---@type LazySpec
local M = {
    {
        "tpope/vim-fugitive",

        -- Load immediately to enable `nvim -c 'Git mergetool'`
        lazy = false,

        -- event = 'VeryLazy',

        keys = {
            -- { '<leader>g<Space>', ':Git<Space>',                                              desc = 'Start Fugitive command (:Git )' },
            { "<leader>gg", ":Git<CR>", desc = "Git status (fugitive)" },
            {
                "<leader>gmt",
                function() vim.cmd "Git mergetool -y" end,
                desc = "[g]it [m]erge[t]ool",
            },
            {
                "<leader>gdt",
                function() vim.cmd "Git difftool -y" end,
                desc = "[g]it [d]iff[t]ool",
            },
        },
    },

    -- GitHub integration
    -- 'tpope/vim-rhubarb',

    {
        -- Adds git related signs to the gutter, as well as utilities for managing changes
        "lewis6991/gitsigns.nvim",
        event = "VeryLazy",
        opts = {
            -- See `:help gitsigns.txt`
            sign_priority = 50,  -- set higher priority than diagnostic signs

            signs = {
                -- add = { text = '+' },
                -- change = { text = '~' },
                -- delete = { text = '_' },
                -- topdelete = { text = '‾' },
                -- changedelete = { text = '~' },
            },

            -- Executed when attaching to new git file
            on_attach = function(bufnr)
                local function nmap(lhs, rhs, desc)
                    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
                end

                -- Gitsigns mappings
                nmap(
                    "<leader>ghp",
                    function() require("gitsigns").nav_hunk("prev") end,
                    "[g]it: [h]unk [p]revious"
                )
                nmap(
                    "[g",
                    function() require("gitsigns").nav_hunk("prev") end,
                    "[g]it: Previous Hunk"
                )

                nmap(
                    "<leader>ghn",
                    function() require("gitsigns").nav_hunk("next") end,
                    "[g]it: [h]unk [n]ext"
                )
                nmap(
                    "]g",
                    function() require("gitsigns").nav_hunk("next") end,
                    "[g]it: Next Hunk"
                )
                nmap(
                    "<leader>ghr",
                    function() require("gitsigns").reset_hunk() end,
                    "[g]it: [h]unk [r]eset"
                )
                nmap(
                    "<leader>ghd",
                    function() require("gitsigns").preview_hunk_inline() end,
                    "[g]it: Preview [h]unk [d]iff"
                )
            end,
        },
    },

    {
        "akinsho/git-conflict.nvim",
        -- event = "VeryLazy", NOTE: plugin seems broken when loaded on VeryLazy
        -- https://github.com/akinsho/git-conflict.nvim?tab=readme-ov-file#configuration
        ---@type GitConflictUserConfig
        opts = {
            default_mappings = false,    -- disable buffer local mapping created by this plugin
            -- default_commands = true,  -- disable commands created by this plugin
            disable_diagnostics = true,  -- This will disable the diagnostics in a buffer whilst it is conflicted
            -- list_opener = "copen",    -- command or function to open the conflicts list
            highlights = {
                -- incoming = "DiffAdd",
                -- current = "DiffText",
                incoming = "DiffChange",
                current = "DiffAdd",
                ancestor = "DiffDelete",
            },
        },
        config = function(self, opts)
            local git_conflict = require("git-conflict")
            git_conflict.setup(opts)

            ---@param lhs string[]|string
            ---@param rhs string|function
            ---@param description? string|nil
            local function nmap(lhs, rhs, description)
                description = description or
                    ((type(rhs) == "string" and rhs) or nil)
                if type(description) == "string" then
                    description = "conflict: " .. description
                end
                if type(lhs) == "string" then
                    lhs = { lhs }
                end
                for _, lhs_item in ipairs(lhs) do
                    vim.keymap.set("n", lhs_item, rhs, { desc = description })
                end
            end

            nmap({ "co", "<leader>gmh" }, "<Plug>(git-conflict-ours)",
                "choose ours")
            nmap({ "ct", "<leader>gml" }, "<Plug>(git-conflict-theirs)",
                "choose theirs")
            nmap({ "cb", "<leader>gmb" }, "<Plug>(git-conflict-base)",
                "choose base")
            nmap({ "cb", "<leader>gmB" }, "<Plug>(git-conflict-both)",
                "choose both")
            nmap({ "c0", "<leader>gm0" }, "<Plug>(git-conflict-none)",
                "choose none")
            nmap({ "[x", "<leader>gmn" }, "<Plug>(git-conflict-prev-conflict)",
                "previous conflict")
            nmap({ "]x", "<leader>gmp" }, "<Plug>(git-conflict-next-conflict)",
                "next conflict")
            nmap("<leader>gmq", function()
                vim.cmd.cexpr("[]")
                -- vim.cmd("GitConflictRefresh")
                vim.cmd("GitConflictListQf")
            end, "send to quickfix")

            vim.api.nvim_create_autocmd("User", {
                pattern = "GitConflictDetected",
                callback = function()
                    local bufnr = 0
                    local conflict_count = git_conflict.conflict_count(bufnr)
                    local message = ("Conflict detected in %s (%d conflicts)")
                        :format(vim.fn.expand("%"), conflict_count)
                    vim.schedule(function()
                        vim.notify(message, vim.log.levels.WARN)
                    end)
                end,
                group = vim.api.nvim_create_augroup(
                    "GitConflictDetected_augroup",
                    { clear = true }),
            })

            vim.api.nvim_create_autocmd("User", {
                pattern = "GitConflictResolved",
                callback = function()
                    local git_utils = require("user.utils.git")
                    local conflict_file = vim.fn.expand("%")
                    local message = ("Conflict resolved in %s")
                        :format(conflict_file)
                    vim.schedule(function()
                        vim.notify(message)

                        if not git_utils.is_unmerged_file(conflict_file) then
                            -- vim.notify(
                            --     "[DEBUG] aborting, file is already merged")
                            return
                        end

                        -- local choice_list = {
                        --     {
                        --         label = "Cancel",
                        --         on_select = function()
                        --         end,
                        --     },
                        --     {
                        --         label = "Add entire file",
                        --         on_select = function()
                        --             local is_written = pcall(vim.cmd.write)
                        --             if not is_written then
                        --                 vim.notify(
                        --                     "aborting git add, could not write to file: " ..
                        --                     conflict_file, vim.log.levels.ERROR)
                        --                 return
                        --             end
                        --             if git_utils.add_file(conflict_file) then
                        --                 vim.notify("added file to git index: " ..
                        --                     conflict_file)
                        --             end
                        --         end,
                        --     },
                        --     -- {
                        --     --     -- value = "interactive",
                        --     --     label = "Interactive",
                        --     --     on_select = function ()
                        --     --         vim.notify('TODO interactive add', vim.log.levels.ERROR)
                        --     --     end,
                        --     -- },
                        -- }
                        -- local prompt =
                        --     ("All conflicts resolved! Add to git index? (%s)")
                        --     :format(conflict_file)
                        -- vim.ui.select(choice_list,
                        --     {
                        --         prompt = prompt,
                        --         format_item =
                        --             function(item) return item.label end,
                        --     },
                        --     function(chosen_item)
                        --         if chosen_item == nil then
                        --             return
                        --         end
                        --         vim.notify("chose item: " ..
                        --             vim.inspect(chosen_item))
                        --         chosen_item.on_select()
                        --     end)

                        local ui = require("user.utils.ui")
                        ui.ui_confirm(
                            ("All conflicts resolved! Add to git index? (%s)")
                            :format(conflict_file),
                            {
                                on_accept = function()
                                    local is_written = pcall(vim.cmd.write)
                                    if not is_written then
                                        vim.notify(
                                            "aborting git add, could not write to file: " ..
                                            conflict_file, vim.log.levels.ERROR)
                                        return
                                    end
                                    if git_utils.add_file(conflict_file) then
                                        vim.notify("added file to git index: " ..
                                            conflict_file)
                                    end
                                end,
                                on_deny = function()
                                    vim.notify("denied git add")
                                end,
                            },
                            {
                                choices = { yes = "Add entire file", no = "Cancel", },
                            }
                        )
                    end)
                end,
                group = vim.api.nvim_create_augroup(
                    "GitConflictResolved_augroup",
                    { clear = true }),
            })
        end,
    },
}

return M
