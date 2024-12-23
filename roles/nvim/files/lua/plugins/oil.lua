return {
	"stevearc/oil.nvim",
	event = "VimEnter", -- lazy load after vim startup
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	config = function()
		local oil = require("oil")
		oil.setup({
			default_file_explorer = true, -- replace netrw with oil
			delete_to_trash = true, -- use the macos trash dir instead of completely removing the files
			columns = { "icon" }, -- icon, permissions, size, mtime
			watch_for_changes = true, -- reload on file change
			view_options = {
				show_hidden = true,
				is_hidden_file = function(name, bufnr)
					return vim.startswith(name, ".")
				end,
				-- always hide ../ directory
				is_always_hidden = function(name, bufnr)
					return vim.startswith(name, "..")
				end,
			},
			-- KEYMAPS
			keymaps = {
				["?"] = "actions.show_help", -- show help menu
				["<CR>"] = "actions.select", -- open selected file/directory
				["<C-p>"] = "actions.preview", -- preview
				["<C-c>"] = "actions.close", -- close
				["<C-o>"] = "actions.open_external", -- open with default app
				["%"] = "actions.refresh", -- refresh
				["<BS>"] = "actions.parent", -- move to parent directory
				["_"] = "actions.open_cwd", -- move to current working directory
				["cd"] = "actions.cd", -- change working directory
				["cs"] = "actions.change_sort", -- change sorting (name, size, ..)
				["H"] = "actions.toggle_hidden", -- show/hide hidden files
			},
		})
		vim.api.nvim_set_keymap("n", "<leader>e", "<CMD>Oil<CR>", { noremap = true, silent = true })
	end,
}
