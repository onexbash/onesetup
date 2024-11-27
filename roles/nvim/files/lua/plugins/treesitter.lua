return {
	"nvim-treesitter/nvim-treesitter",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate", -- run tsupdate on startup
	dependencies = {
		"windwp/nvim-ts-autotag",
	},
	config = function()
		local tsconfig = require("nvim-treesitter.configs")
		tsconfig.setup({
			sync_install = true, -- install parsers synchronously => nvim will wait to load till parsers are installed
			-- syntax highlighting
			highlight = {
				enable = true,
			},
			-- indentation
			indent = {
				enable = true,
			},
			-- autotagging
			autotag = {
				enable = true,
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
			-- install parsers
			ensure_installed = {
				"angular", -- angular
				"norg", -- neorg
				-- "asm", -- assembly
				-- "astro", -- astro
				"awk", -- awk
				"bash", -- bash
				"c", -- C
				"c_sharp", -- C#
				"cpp", -- C++
				"css", -- css
				"csv", -- csv
				"dockerfile", -- dockerfiles
				"git_config", -- gitconfig
				-- "git_rebase", -- git rebase
				-- "gitattributes", -- git attributes
				-- "gitcommit", -- git commits
				"gitignore", -- gitignore
				"go", -- golang
				"gpg", -- GPG
				"graphql", -- graphql
				"hcl", -- hashicorp config lang
				"html", -- html
				-- "http", -- http
				"hyprlang", -- Hyprland config lang
				"ini", -- ini config files
				"java", -- java
				"javascript", -- javascript
				"jq", -- jq json parser
				"lua", -- lua
				"markdown", -- markdown
				"markdown_inline", -- inline markdown
				-- "passwd", -- linux passwd files
				-- "printf", -- printf format strings
				"prisma", -- prisma database toolkit
				-- "properties", -- property files
				"python", -- python
				-- "query", -- treesitter query lang
				-- "readline", -- readline config files
				-- "regex", -- regular expressions
				"requirements", -- python requirements.txt files
				"ruby", -- ruby
				"rust", -- rust
				"scss", -- sassy css
				"sql", -- sql
				"ssh_config", -- ssh config files
				"styled", -- react: styled components for css-in-js
				"svelte", -- svelte
				"swift", -- swift
				"terraform", -- terraform
				"tmux", -- tmux config files
				"toml", -- toml
				"tsx", -- react: typed jsx components
				"typescript", -- typescript
				"vim", -- vimscript
				"vue", -- vue.js
				"xml", -- xml
				"yaml", -- yaml / yml
				-- "zig", -- zig
			},
		})
	end,
}
