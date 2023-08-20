--vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"
vim.cmd.highlight("CursorLineNr cterm=bold ctermbg=15 ctermfg=8 guifg=#ccbb44")
vim.cmd.highlight("DiagnosticVirtualTextError guibg=none")
vim.cmd.highlight("DiagnosticVirtualTextWarn guibg=none")
vim.cmd.highlight("DiagnosticVirtualTextInfo guibg=none")
vim.cmd.highlight("DiagnosticVirtualTextHint guibg=none")
vim.cmd.highlight("DiagnosticVirtualTextOk guibg=none")

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

