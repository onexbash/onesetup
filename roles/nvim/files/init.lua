-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("globals")
require("keymaps")
require("options")

-- setup lazy.nvim
require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	defaults = {
		lazy = false,
	},
	-- check for updates
	checker = {
		enabled = true,
		notify = true, -- get notification when updates are available
		frequency = 3600, -- 3600seconds => every hour
	},
	-- check for config file changes
	change_detection = {
		enabled = true,
		notify = false,
	},
	ui = {
		size = { width = 0.8, height = 0.8 },
		border = "single",
		title = "lazy.nvim",
	},
})
