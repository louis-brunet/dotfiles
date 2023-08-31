-- vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move up" })

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", [["_dP]])

vim.keymap.set({"n", "v"}, "<leader>y", [["+y]], { desc = 'Yank to system clipboard' })
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])

vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set({"i", "n", "v", "s"}, "ù", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "New tmux session (tmux-sessionizer)" })
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format current buffer" })

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- exit terminal mode with Esc
vim.cmd("tnoremap <Esc> <C-\\><C-n>")

vim.keymap.set("n", "<C-w>Q", vim.cmd.tabclose, { desc = "Close current tab" })
vim.keymap.set("n", "<A-l>", vim.cmd.tabnext, { desc = "Next tab" })
vim.keymap.set("n", "<A-h>", vim.cmd.tabprevious, { desc = "Previous tab" })

-- toggle transparent background
vim.keymap.set({"n", "v"}, "<leader>t", vim.cmd.TransparentToggle, { desc = "Toggle transparent background" })

vim.keymap.set("i", "<M-BS>", "<C-W>", { desc = "Delete word backwards" })

