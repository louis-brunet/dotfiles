-- [[ Basic Keymaps ]]

-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- TODO: "move left/right" keybind that won't mess with "" (unnamed register for pastes)
vim.keymap.set("v", "H", "dhP`[v`]", { desc = "Move selection left" })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("v", "L", "dp`[v`]", { desc = "Move selection right" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "[J]oin lines" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page [D]own" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page [U]p" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result" })

vim.keymap.set("x", "<leader>p", [["_dP]], { desc = 'Delete and [P]aste without yanking' })
-- vim.keymap.set({"n", "v"}, "<leader>d", [["_d]], { desc = '[D]elete without yanking' })

vim.keymap.set({"n", "v"}, "<leader>y", [["+y]], { desc = 'Yank to system clipboard' })
vim.keymap.set("n", "<leader>Y", [["+Y]])


-- Alternate ways to get out of insert mode (<C-c>, ù)
vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set({"i", "n", "v", "s"}, "ù", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "New tmux session (tmux-sessionizer)" })
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "[F]ormat current buffer" })

-- -- Navigate quickfix list (:h quickfix)
-- vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
-- vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")

-- -- Navigate location list (:h location-list)
-- vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
-- vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- exit terminal mode with Esc
vim.cmd("tnoremap <Esc> <C-\\><C-n>")

vim.keymap.set("n", "<C-w>Q", vim.cmd.tabclose, { desc = "Close current tab" })
vim.keymap.set("n", "<M-L>", vim.cmd.tabnext, { desc = "Next tab" })
vim.keymap.set("n", "<M-H>", vim.cmd.tabprevious, { desc = "Previous tab" })

-- toggle transparent background
vim.keymap.set({"n", "v"}, "<leader>t", vim.cmd.TransparentToggle, { desc = "Toggle [T]ransparent background" })

-- A-Backspace to delele word backwards (C-BS is captured by tmux as C-H)
vim.keymap.set("i", "<M-BS>", "<C-W>", { desc = "Delete word backwards" })

-- Better indenting
vim.keymap.set('v', '<', '<gv', { desc = 'Indent left' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right' })
vim.keymap.set('n', '<', '<<_', { desc = 'Indent left' })
vim.keymap.set('n', '>', '>>_', { desc = 'Indent right' })

