-- INDENTATION --
vim.opt.expandtab = true -- use spaces instead of tabs
vim.opt.shiftwidth = 2 -- indent size
vim.opt.tabstop = 2 -- how many spaces is a tab
vim.opt.softtabstop = 2 -- the same i guess
vim.opt.breakindent = true -- smart indenting

-- disable some providers
vim.g.loaded_perl_provider = 0 -- perl
vim.g.loaded_ruby_provider = 0 -- ruby
vim.g.loaded_python3_provider = 0 -- python
vim.opt.undofile = true -- enable persistent undo history

-- CLIPBOARD --
vim.opt.clipboard = "unnamedplus" -- share system clipboard with nvim

-- FILE EXPLORER --
-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- COLORS --
vim.opt.termguicolors = true -- enable 24-bit color support

-- LINE NUMBERS
vim.opt.number = true -- show line numbers
vim.opt.relativenumber = true -- show relative line numbers

-- UI / UX
-- keep 8 lines above/below cursor till end of file
vim.opt.scrolloff = 8
-- highlight cursorline
vim.opt.cursorline = true
-- highlight on yank
AUTOCMD("TextYankPost", {
	group = AUGROUP("highlight_yank", { clear = true }),
	pattern = "*",
	desc = "Highlight selection on yank",
	callback = function()
		vim.highlight.on_yank({ timeout = 200, visual = true })
	end,
})
