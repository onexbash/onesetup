return {
	{
		"catppuccin/nvim",
		lazy = false,
		name = "catppuccin",
		priority = 1000,
		config = function()
			local catppuccin = require("catppuccin")
			catppuccin.setup({
				flavour = "mocha",
				transparent_background = true,
				-- HIGHLIGHT COLOR OVERRIDES --
				-- :highlight to show all highlight groups
				highlight_overrides = {
					mocha = function(mocha)
						return {
							-- syntax
							Comment = { fg = mocha.surface2 },
							-- line numbers
							LineNr = { fg = mocha.red },
							CursorLineNr = { fg = mocha.red },
							LineNrAbove = { fg = mocha.sky },
							LineNrBelow = { fg = mocha.sky },
						}
					end,
				},
				-- PLUGIN INTEGRATIONS --
				integrations = {
					-- alpha.nvim
					alpha = true,
					-- nvim-cmp
					cmp = true,
					-- indent-blankline.nvim
					indent_blankline = {
						enabled = true,
						scope_color = "lavender",
						colored_indent_levels = true,
					},
					-- nvim-lspconfig
					native_lsp = {
						enabled = true,
						virtual_text = {
							errors = { "italic" },
							hints = { "italic" },
							warnings = { "italic" },
							information = { "italic" },
							ok = { "italic" },
						},
						underlines = {
							errors = { "underline" },
							hints = { "underline" },
							warnings = { "underline" },
							information = { "underline" },
							ok = { "underline" },
						},
						inlay_hints = {
							background = true,
						},
					},
					-- markdown
					markdown = true,
					-- mason.nvim
					mason = true,
					-- nvim-surround
					nvim_surround = true,
					-- nvim-treesitter
					treesitter = true,
					-- telescope.nvim
					telescope = {
						enabled = true,
						style = "nvchad",
					},
					-- trouble.nvim
					lsp_trouble = true,
					-- which-key.nvim
					which_key = true,
				},
			})

			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
