local M = {}

-- get visually selected text
local function get_visual_selection()
	local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
	local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))
	local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
	if #lines == 0 then
		return ""
	end
	lines[#lines] = string.sub(lines[#lines], 1, end_col)
	lines[1] = string.sub(lines[1], start_col + 1)
	return table.concat(lines, "\n")
end

-- send openai api request
local function ask_chatgpt(prompt)
	local api_key = os.getenv("OPENAI_API_KEY")
	if not api_key then
		vim.api.nvim_err_writeln("OpenAI API key not found")
		return
	end

	local cmd = "curl -s -X POST https://api.openai.com/v1/engines/davinci-codex/completions "
		.. "-H 'Content-Type: application/json' "
		.. "-H 'Authorization: Bearer "
		.. api_key
		.. "' "
		.. '-d \'{"prompt": "'
		.. prompt
		.. '", "max_tokens": 100}\''

	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()

	local json = vim.fn.json_decode(result)
	if json and json.choices and json.choices[1] and json.choices[1].text then
		vim.api.nvim_out_write(json.choices[1].text .. "\n")
	else
		vim.api.nvim_err_writeln("Failed to get response from OpenAI")
	end
end

function M.ask()
	local selection = get_visual_selection()
	if selection and #selection > 0 then
		local prompt = "Explain the following code:\n\n" .. selection
		ask_chatgpt(prompt)
	else
		vim.api.nvim_err_writeln("No code selected")
	end
end

return M
