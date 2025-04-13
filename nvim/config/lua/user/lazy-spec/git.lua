local merge_conflict_pattern =
[[/<<<<.*\n\(\(====\)\@!.*\n\)*====.*\n\(\(>>>>\)\@!.*\n\)*>>>>.*$/]]

-- ---@param flags { nojump: boolean|nil, global: boolean|nil, fuzzy: boolean|nil } | nil
-- ---@return string
-- local function merge_conflict_pattern_with_flags(flags)
--     flags = flags or {}
--     local flags_str = ''
--
--     if flags.fuzzy then flags_str = flags_str .. 'f' end
--     if flags.global then flags_str = flags_str .. 'g' end
--     if flags.nojump then flags_str = flags_str .. 'j' end
--
--     return merge_conflict_pattern .. flags_str
-- end

---@param opts { filenames: string|nil, loclist: boolean|nil, open: boolean|nil }|nil
local function list_merge_conflicts(opts)
    opts = opts or {}
    opts.filenames = opts.filenames or "%"
    local pattern = merge_conflict_pattern

    local list_cmd = "vimgrep"
    local open_cmd = "copen"
    if opts.loclist then
        list_cmd = "lvimgrep"
        open_cmd = "lopen"
    end

    local ok, _ = pcall(
        vim.api.nvim_cmd,
        {
            cmd = list_cmd,
            args = { pattern, opts.filenames },
            mods = { silent = true },
        },
        {}
    )
    if not ok then
        vim.notify("[list_merge_conflicts]  no merge conflicts",
            vim.log.levels.INFO)
        return
    end

    if opts.open then
        vim.cmd(open_cmd)
    end
end

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

                -- Other mappings only used in a git buffer
                -- TODO: more generic diffget keybinds, the handlers should check:
                --  1. how many buffers ?
                --  2. which layout ? (why different in desktop ~/code/test/mergeconflict vs neoxia ~/code/test/merge*_nobase ?)
                --
                -- assumes nvimdiff3 layout (LOCAL BASE REMOTE / MERGED), or (LOCAL MERGED REMOTE)
                nmap(
                    "<leader>gmh",
                    function() vim.cmd.diffget(vim.fn.tabpagebuflist()[1]) end,
                    "[g]it [m]erge diffget left (LOCAL) "
                )
                nmap(
                    "<leader>gmk",
                    function() vim.cmd.diffget(vim.fn.tabpagebuflist()[2]) end,
                    "[g]it [m]erge diffget middle (BASE)"
                )
                nmap(
                    "<leader>gml",
                    function() vim.cmd.diffget(vim.fn.tabpagebuflist()[3]) end,
                    "[g]it [m]erge diffget right (REMOTE)"
                )

                nmap(
                    "<leader>gmc",
                    function() list_merge_conflicts({ open = true }) end,
                    "[g]it [m]erge [c]onflicts quickfix"
                )
            end,
        },
    },

    {
        "akinsho/git-conflict.nvim",
        -- https://github.com/akinsho/git-conflict.nvim?tab=readme-ov-file#configuration
        opts = {
            -- default_mappings = true,  -- disable buffer local mapping created by this plugin
            -- default_commands = true,  -- disable commands created by this plugin
            disable_diagnostics = true,  -- This will disable the diagnostics in a buffer whilst it is conflicted
            -- list_opener = "copen",    -- command or function to open the conflicts list
            -- highlights = {            -- They must have background color, otherwise the default color will be used
            --     incoming = "DiffAdd",
            --     current = "DiffText",
            -- },
        },
    },
}

return M
