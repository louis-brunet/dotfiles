---@module 'lazy'

---@type LazySpec
return {
    -- {
    --     dir = "~/code/opencode-workflow/apps/opencode-agent.nvim",
    --     dependencies = "nickjvandyke/opencode.nvim",
    -- },

    {
        "nickjvandyke/opencode.nvim",
        version = "*",  -- Latest stable release
        dependencies = {
            { dir = "~/code/opencode-workflow/apps/opencode-agent.nvim" },

            {
                -- `snacks.nvim` integration is recommended, but optional
                ---@module "snacks" <- Loads `snacks.nvim` types for configuration intellisense
                "folke/snacks.nvim",
                -- optional = true,
                opts = {
                    input = {},  -- Enhances `ask()`
                    picker = {  -- Enhances `select()`
                        actions = {
                            opencode_send = function(...) return require(
                                "opencode").snacks_picker_send(...) end,
                        },
                        win = {
                            input = {
                                keys = { ["<a-a>"] = { "opencode_send", mode = { "n", "i" } }, },
                            },
                        },
                    },
                },
            },
        },
        config = function()
            local opencode_port = nil

            ---@type opencode.Opts
            vim.g.opencode_opts = {
                -- Your configuration, if any; goto definition on the type or field for details
                contexts = vim.tbl_extend(
                    "force",
                    require("opencode_agent.prompts").contexts,
                    {
                        -- ["@my-custom-context"] = function(ctx)
                        --     -- local range = vim.inspect(ctx.range)
                        --     local range = ctx:this()
                        --     return "hello custom context, this: " .. range
                        --     -- ctx.buf
                        --     -- ctx.range
                        --     -- return ctx:git_diff()
                        -- end,
                    }
                ),
                prompts = vim.tbl_extend(
                    "force",
                    require("opencode_agent.prompts").prompts,
                    {
                        -- create_ticket = { prompt = "......@this, @diff, @my-custom-context, .....", submit = true },
                        -- my_custom_prompt = {
                        --     prompt = "hello custom prompt: @my-custom-context",
                        --     ask = true,
                        --     submit = false,
                        -- },
                    }
                ),
                server = {
                    -- port = function (callback)
                    -- end,
                    port = opencode_port,
                    start = function()
                        require("opencode_agent.server.tmux").start({
                            port = opencode_port,
                        })
                    end,
                    stop = function()
                        require("opencode_agent.server.tmux").stop()
                    end,
                    toggle = function()
                        require("opencode_agent.server.tmux").toggle()
                    end,
                },
                select = {},
                ask = {
                    snacks = {
                        icon = "󰚩 ",
                        win = {
                            title_pos = "left",
                            relative = "win",
                            row = -1,
                            col = -1,
                            -- anchor = "SE",
                            keys = { i_cr = { desc = "submit" } },
                            b = { completion = true },
                            bo = { filetype = "opencode_ask" },
                            on_buf = function(win)
                                -- Make sure your completion plugin has the LSP source enabled,
                                -- either by default or for the `opencode_ask` filetype!
                                vim.lsp.start(
                                    require("opencode.ui.ask.cmp"),
                                    { bufnr = win.buf }
                                )
                            end,
                        },
                    },
                },
                events = {},
                -- lsp = {
                --     -- enabled = true,
                -- },
            }

            vim.api.nvim_create_user_command("Opencode", function()
                require("opencode").select()
            end, { desc = "Select opencode functionality" })

            local lualine = require("lualine")
            local existing_lualine_section = (
                (lualine.get_config() or {}).sections or {}
            ).lualine_x or {}
            lualine.setup({
                sections = {
                    lualine_x = vim.list_extend(
                        { { require("opencode").statusline } },
                        existing_lualine_section
                    ),
                },
            })

            vim.o.autoread = true  -- Required for `opts.events.reload`

            -- Recommended/example keymaps
            vim.keymap.set(
                { "n", "x" }, "<leader>oa",
                function()
                    require("opencode").ask("@this: ", { submit = true })
                end, { desc = "Ask opencode…" }
            )
            vim.keymap.set(
                { "n", "x" }, "<leader>ox",
                function() require("opencode").select() end,
                { desc = "Execute opencode action…" }
            )
            vim.keymap.set(
                { "n", "t" }, "<leader>ot",
                function() require("opencode").toggle() end,
                { desc = "Toggle opencode" }
            )

            vim.keymap.set(
                { "n", "x" }, "<leader>or",
                function() return require("opencode").operator("@this ") end,
                { desc = "Add range to opencode", expr = true }
            )
            vim.keymap.set(
                "n", "<leader>ol",
                function() return require("opencode").operator("@this ") .. "_" end,
                { desc = "Add line to opencode", expr = true }
            )

            -- vim.keymap.set("n", "<S-C-u>",
            --     function() require("opencode").command("session.half.page.up") end,
            --     {
            --         desc = "Scroll opencode up"
            --     })
            -- vim.keymap.set("n", "<S-C-d>",
            --     function() require("opencode").command("session.half.page.down") end,
            --     {
            --         desc = "Scroll opencode down"
            --     })
            --
            -- -- You may want these if you use the opinionated `<C-a>` and `<C-x>` keymaps above — otherwise consider `<leader>o…` (and remove terminal mode from the `toggle` keymap)
            -- vim.keymap.set("n", "+", "<C-a>",
            --     {
            --         desc = "Increment under cursor",
            --         noremap = true
            --     })
            -- vim.keymap.set("n", "-", "<C-x>",
            --     {
            --         desc = "Decrement under cursor",
            --         noremap = true
            --     })
        end,
    },
}
