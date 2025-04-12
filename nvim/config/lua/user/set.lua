-- [[ Setting options ]]
-- See `:help vim.o`

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
-- vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true
vim.o.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "auto:1-2"

-- Decrease update time
vim.o.updatetime = 50  -- 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

vim.o.termguicolors = true

--vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number,screenline"
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false
vim.opt.spell = false

vim.opt.swapfile = false
vim.opt.backup = false

-- incremental search
vim.opt.incsearch = true

vim.opt.scrolloff = 8
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

---@param diagnostic_code string|integer
---@return string
local function format_diagnostic_code_suffix(diagnostic_code)
    local suffix = ""
    local code_str = diagnostic_code
    if code_str ~= nil then
        if type(code_str) ~= "string" then
            code_str = vim.inspect(code_str)
        end
        suffix = (" [%s]"):format(code_str)
    end
    return suffix
end

---@param diagnostic vim.Diagnostic
---@return string
local function format_diagnostic(diagnostic)
    return diagnostic.message .. format_diagnostic_code_suffix(diagnostic.code)
end

-- -- local diagnostic_max_severity_for_virtual_lines = vim.diagnostic.severity.ERROR
-- local diagnostic_max_severity_for_virtual_lines = -1
---@type vim.diagnostic.Opts
local diagnostic_opts = {
    underline = true,
    severity_sort = true,  -- show higher severity diagnostics first
    update_in_insert = true,
    -- virtual_lines = {
    --     format = function(diagnostic)
    --         if diagnostic.severity > diagnostic_max_severity_for_virtual_lines then
    --             return ""
    --         end
    --         return format_diagnostic(diagnostic)
    --     end,
    -- },
    virtual_text = {
        -- severity = {
        --     vim.diagnostic.severity.ERROR,
        --     vim.diagnostic.severity.WARN,
        --     vim.diagnostic.severity.INFO,
        -- },
        virt_text_pos = "eol",
        source = false, -- "if_many",
        suffix = function(diagnostic)
            return format_diagnostic_code_suffix(diagnostic.code)
        end,
    },
    float = { source = "if_many", severity_sort = true },
    signs = {
        -- severity = {vim.diagnostic.severity.ERROR,vim.diagnostic.severity.WARN},
        text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = " ",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
            [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
            [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
            [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
        },
        linehl = {},
    },
}
vim.diagnostic.config(diagnostic_opts)

-- Folding options
vim.api.nvim_set_option_value("foldmethod", "expr", {})
vim.api.nvim_set_option_value("foldexpr", "v:lua.vim.treesitter.foldexpr()", {})
vim.api.nvim_set_option_value("foldtext", "", {})       -- show first line with regular buffer highlight
vim.api.nvim_set_option_value("foldenable", false, {})  -- hide folds by default
