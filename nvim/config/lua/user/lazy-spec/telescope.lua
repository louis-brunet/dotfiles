---@class TelescopePickerKeymap
---@field [1] fun():nil
---@field desc string

local function telescope_multigrep(opts)
    local telescope_pickers = require("telescope.pickers")
    local telescope_finders = require("telescope.finders")
    local telescope_make_entry = require("telescope.make_entry")
    local telescope_config = require("telescope.config").values
    local telescope_actions = require("telescope.actions")

    opts = opts or {}
    opts.cwd = opts.cwd or vim.uv.cwd()

    local finder = telescope_finders.new_async_job({
        command_generator = function(prompt)
            if not prompt or prompt == "" then
                return nil
            end

            local separator = "  "
            local pieces = vim.split(prompt, separator)
            if #pieces == 0 then
                return nil
            end
            local args = { "rg" }

            -- local regexp = ""

            for i = 1, math.max(1, #pieces - 1), 1 do
                local piece = pieces[i]
                if piece and piece ~= "" then
                    table.insert(args, "--regexp")
                    table.insert(args, piece)
                    -- regexp = regexp .. "(?=" .. piece .. ")"
                end
            end

            -- if regexp ~= "" then
            --     table.insert(args, "--regexp")
            --     table.insert(args, regexp)
            --
            --     if #pieces > 1 then
            --         table.insert(args, "--glob")
            --         table.insert(args, pieces[#pieces])
            --     end
            -- end

            if #pieces > 1 then
                table.insert(args, "--glob")
                table.insert(args, pieces[#pieces])
            end

            args = vim.iter({
                args,
                {
                    "--color=never",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                    "--smart-case",
                    "--hidden",
                },
            }):flatten():totable()
            return args
        end,
        entry_maker = telescope_make_entry.gen_from_vimgrep(opts),
        cwd = opts.cwd,
    })

    telescope_pickers.new(
        opts,
        {
            finder = finder,
            prompt_title = "Multigrep",
            debounce = 100,
            previewer = telescope_config.grep_previewer(opts),
            sorter = require("telescope.sorters").highlighter_only(opts),
            attach_mappings = function(_, map)
                map(
                    "i", "<c-space>",
                    telescope_actions.to_fuzzy_refine
                )
                return true
            end,
        }
    ):find()
end

---@return table<string, TelescopePickerKeymap>
local function create_telescope_keymaps()
    local telescope_builtin = require("telescope.builtin")

    return {
        ["<leader>sf"] = {
            function()
                telescope_builtin.find_files({
                    hidden = false,
                    no_ignore = false,
                    no_ignore_parent = false,
                })
            end,
            desc = "search [f]iles",
        },
        ["<leader>sF"] = {
            function()
                telescope_builtin.find_files({
                    hidden = true,
                    no_ignore = true,
                    no_ignore_parent = true,
                })
            end,
            desc = "search [F]iles (hidden, gitignored)",
        },
        ["<leader>?"] = {
            telescope_builtin.oldfiles,
            desc = "[?] Find recently opened files",
        },
        ["<leader><space>"] = {
            telescope_builtin.buffers,
            desc = "[ ] Find existing buffers",
        },
        ["<leader>/"] = {
            telescope_builtin.current_buffer_fuzzy_find,
            desc = "[/] Find in current buffer",
        },
        ["<leader>gf"] = {
            telescope_builtin.git_files,
            desc = "Search [g]it [f]iles",
        },
        ["<leader>gs"] = {
            telescope_builtin.git_status,
            desc = "Search [g]it [s]tatus",
        },
        ["<leader>gS"] = {
            telescope_builtin.git_stash,
            desc = "Search [g]it [S]tash",
        },
        ["<leader>gb"] = {
            telescope_builtin.git_branches,
            desc = "Search [g]it [b]ranches",
        },
        ["<leader>gc"] = {
            telescope_builtin.git_commits,
            desc = "Search [g]it [c]ommits",
        },
        ["<leader>gC"] = {
            telescope_builtin.git_bcommits,
            desc = "Search [g]it [C]ommits in current buffer",
        },
        ["<leader>sh"] = { telescope_builtin.help_tags, desc = "search [h]elp" },
        ["<leader>sw"] = {
            telescope_builtin.grep_string,
            desc = "search current [w]ord",
        },
        -- ["<leader>sg"] = {
        --     function()
        --         telescope_builtin.live_grep({ additional_args = { "--hidden" } })
        --     end,
        --     desc = "search with [g]rep",
        -- },
        ["<leader>sg"] = { telescope_multigrep, desc = "search with multi [g]rep" },
        ["<leader>sd"] = {
            telescope_builtin.diagnostics,
            desc = "search [d]iagnostics",
        },
        ["<leader>sr"] = { telescope_builtin.resume, desc = "[r]esume last search" },
        ["<leader>sp"] = {
            function()
                local data_path = vim.fn.stdpath("data")
                if type(data_path) == "table" then
                    data_path = data_path[1]
                end
                local lazy_path = vim.fs.joinpath(data_path, "lazy")
                if not vim.fn.isdirectory(lazy_path) then
                    vim.notify(
                        "directory does not exist: " .. lazy_path,
                        vim.log.levels.ERROR,
                        { title = "telescope.lua" }
                    )
                    return
                end
                telescope_builtin.find_files({
                    cwd = vim.fs.joinpath(data_path, "lazy"),
                })
            end,
            desc = "search lazy [p]lugin files",
        },
    }
end

---@param border_chars_box string[]
---@param border_chars_merge_top string[]
---@return function
local function create_custom_layout_strategy(
    border_chars_box,
    border_chars_merge_top
)
    return function(picker, max_columns, max_lines, layout_config)
        local telescope_layout_strategies = require(
            "telescope.pickers.layout_strategies")

        local layout = telescope_layout_strategies.horizontal(picker,
            max_columns, max_lines, layout_config)

        if layout.prompt then
            -- layout.prompt.title = ''
            layout.prompt.borderchars = border_chars_box
        end

        if layout.results then
            layout.results.title = ""
            layout.results.borderchars = border_chars_merge_top
            layout.results.line = layout.results.line - 1
            layout.results.height = layout.results.height + 1
        end

        if layout.preview then
            -- layout.preview.title = ''
            layout.preview.borderchars = border_chars_box
        end

        return layout
    end
end

---@type LazySpec
return {
    -- Fuzzy Finder (files, lsp, etc)
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",

        -- NOTE: Loading Telescope on VeryLazy does not handle keymaps pressed before
        -- nvim was initialized (e.g. `$ nvim<Enter><Space>sf` in terminal)
        -- event = 'VeryLazy',

        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-ui-select.nvim",

            -- Fuzzy Finder Algorithm which requires local dependencies to be built.
            -- Only load if `make` is available. Make sure you have the system
            -- requirements installed.
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                -- NOTE: If you are having trouble with this installation,
                --       refer to the README for telescope-fzf-native for more instructions.
                build = "make",
                cond = function()
                    return vim.fn.executable "make" == 1
                end,
            },
        },

        config = function()
            -- [[ Configure Telescope ]]
            -- See `:help telescope` and `:help telescope.setup()`
            local telescope = require("telescope")
            local telescope_themes = require("telescope.themes")
            local telescope_layout_strategies = require(
                "telescope.pickers.layout_strategies")

            local custom_layout_strategy_name = "custom_horizontal_merged"
            local default_layout_config = {
                width = { padding = 0 },
                height = 0.95,
                prompt_position = "top",
            }
            local border_chars = {
                box = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
                merge_top = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
                -- merge_bottom = { "─", "│", "─", "│", "┌", "┐", "┤", "├" },
            }

            telescope_layout_strategies[custom_layout_strategy_name] =
                create_custom_layout_strategy(
                    border_chars.box,
                    border_chars.merge_top
                )

            telescope.setup({
                extensions = {
                    ["ui-select"] = {
                        telescope_themes.get_cursor {
                            layout_config = {
                                height = 12,
                            },
                            borderchars = {
                                prompt = border_chars.box,
                                preview = border_chars.box,
                                results = border_chars.merge_top,
                            },
                            -- even more opts
                        },

                        -- pseudo code / specification for writing custom displays, like the one
                        -- for "codeactions"
                        -- specific_opts = {
                        --   [kind] = {
                        --     make_indexed = function(items) -> indexed_items, width,
                        --     make_displayer = function(widths) -> displayer
                        --     make_display = function(displayer) -> function(e)
                        --     make_ordinal = function(e) -> string
                        --   },
                        --   -- for example to disable the custom builtin "codeactions" display
                        --      do the following
                        --   codeactions = false,
                        -- }
                    },
                },

                defaults = {
                    layout_strategy = custom_layout_strategy_name,
                    -- layout_strategy = "horizontal",
                    -- layout_strategy = "bottom_pane",
                    -- border = false,
                    -- borderchars = border_chars.box,
                    sorting_strategy = "ascending",
                    path_display = {
                        -- shorten = {
                        --     len = 1,
                        --     exclude = { -2, -1 },
                        -- },
                        truncate = true,
                    },
                    -- see `:h telescope.defaults.layout_config`
                    layout_config = {
                        [custom_layout_strategy_name] = default_layout_config,
                        horizontal = default_layout_config,
                        vertical = default_layout_config,
                        bottom_pane = default_layout_config,
                        -- center = ,
                        -- cursor = ,
                    },
                    mappings = {
                        -- i = {
                        --     ['<C-u>'] = false,
                        --     ['<C-d>'] = false,
                        -- },
                    },
                },
            })

            local telescope_extensions = { "fzf", "ui-select", "notify" }
            for _, extension in ipairs(telescope_extensions) do
                local ok = pcall(telescope.load_extension, extension)
                if not ok then
                    vim.notify(
                        "telescope: could not load extension " .. extension,
                        vim.log.levels.ERROR,
                        { title = "telescope.lua" }
                    )
                end
            end

            for lhs, keymap in pairs(create_telescope_keymaps()) do
                local rhs = keymap[1]
                vim.keymap.set("n", lhs, rhs, { desc = keymap.desc })
            end
        end,
    },

    {
        "piersolenski/telescope-import.nvim",
        dependencies = "nvim-telescope/telescope.nvim",
        config = function()
            local telescope = require("telescope")
            telescope.load_extension("import")
            vim.keymap.set("n", "<leader>si", "<cmd>Telescope import<CR>",
                { desc = "Search [i]mports" })
            -- telescope.setup({
            --     extensions = {
            --         import = {
            --             -- -- Imports can be added at a specified line whilst keeping the cursor in place
            --             -- insert_at_top = true,
            --             -- -- Optionally support additional languages or modify existing languages...
            --             -- custom_languages = {
            --             --     {
            --             --         -- The filetypes that ripgrep supports (find these via `rg --type-list`)
            --             --         extensions = { "js", "ts" },
            --             --         -- The Vim filetypes
            --             --         filetypes = { "vue" },
            --             --         -- Optionally set a line other than 1
            --             --         insert_at_line = 2,  ---@type function|number
            --             --         -- The regex pattern for the import statement
            --             --         regex =
            --             --         [[^(?:import(?:[\"'\s]*([\w*{}\n, ]+)from\s*)?[\"'\s](.*?)[\"'\s].*)]],
            --             --     },
            --             -- },
            --         },
            --     },
            -- })
        end,
    },
}
