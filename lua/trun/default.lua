local M = {}

M.default_cmds = {
	["go"] = { cmd = "go run", args = { "." } },
	["javascript"] = { cmd = "node", args = { "%input%" } },
	["typescript"] = { cmd = "bun run", args = { "%input%" } },
	["lua"] = { cmd = "lua", args = { "%input%" } },
	["python"] = { cmd = "python", args = { "%input%" } },
	["rust"] = { cmd = "cargo run", args = {} },
	["c"] = { cmd = "gcc", args = { "%input%", "-o", "%output%" }, post_cmd = "%output%" },
	["cpp"] = { cmd = "g++", args = { "%input%", "-o", "%output%" }, post_cmd = "%output%" },
}

function M.process_arg(arg, input_file, output_file)
	if arg == "%input%" then
		return input_file
	elseif arg == "%output%" then
		return output_file
	else
		return arg
	end
end

function M.get_default_cmd(file_type)
	local cmd_info = M.default_cmds[file_type]
	if not cmd_info then
		return nil
	end

	local input_file = vim.fn.expand("%:p")
	local output_file = vim.fn.expand("%:p:r") .. ".out"

	local args = {}
	for _, arg in pairs(cmd_info.args) do
		table.insert(args, M.process_arg(arg, input_file, output_file))
	end

	local cmd = cmd_info.cmd .. " " .. table.concat(args, " ")

	if cmd_info.post_cmd then
		local processed_post_cmd = M.process_arg(cmd_info.post_cmd, input_file, output_file)
		cmd = cmd .. " && " .. processed_post_cmd
	end

	return cmd
end

return M
