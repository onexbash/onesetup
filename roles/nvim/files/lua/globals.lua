-- function for keymap options
function _G.keymap_opts(desc, bufnr)
  return { desc = desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
end

-- abbreviations
KEYMAP = vim.keymap.set
NV_KEYMAP = vim.api.nvim_set_keymap
AUTOCMD = vim.api.nvim_create_autocmd
AUGROUP = vim.api.nvim_create_augroup
-- colors
COLORS = {
	-- catppuccin mocha colors
	ROSEWATER = "#f5e0dc",
	FLAMINGO = "#f2cdcd",
	PINK = "#f5c2e7",
	MAUVE = "#cba6f7",
	RED = "#f38ba8",
	MAROON = "#eba0ac",
	PEACH = "#fab387",
	YELLOW = "#f9e2af",
	GREEN = "#a6e3a1",
	TEAL = "#94e2d5",
	SKY = "#89dceb",
	SAPPHIRE = "#74c7ec",
	BLUE = "#89b4fa",
	LAVENDER = "#b4befe",
	TEXT = "#cdd6f4",
	SUBTEXT1 = "#bac2de",
	SUBTEXT0 = "#a6adc8",
	OVERLAY2 = "#9399b2",
	OVERLAY1 = "#7f849c",
	OVERLAY0 = "#6c7086",
	SURFACE2 = "#585b70",
	SURFACE1 = "#45475a",
	SURFACE0 = "#313244",
	BASE = "#1e1e2e",
	MANTLE = "#181825",
	CRUST = "#11111b",
}
