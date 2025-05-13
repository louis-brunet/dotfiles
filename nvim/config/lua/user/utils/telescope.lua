local M = {}

function M.multigrep(opts)
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

function M.plugin_files()
    local telescope_builtin = require("telescope.builtin")
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
end

return M
