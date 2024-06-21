local utils = require("trun.utils")
local popup = require("plenary.popup")
local tmux = require("harpoon.tmux")
local Path = require("plenary.path")

local data_path = vim.fn.stdpath("data")
local config = string.format("%s/trun.json", data_path)

local M = {}

Win_id = nil
Bufnr = nil

local cwd = vim.loop.cwd()

local function get_config()
	if cwd == nil then
		return
	end

	-- load from config and parse from json
	local trun_config = Path:new(config):read()
	if trun_config == nil then
		return
	end

	trun_config = vim.fn.json_decode(trun_config)
	if trun_config == nil then
		return
	end

	return trun_config
end

local function get_cwd_config()
	local trun_config = get_config()
	if trun_config == nil then
		return
	end

	return trun_config[cwd]
end

local function save()
	if cwd == nil then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(Bufnr, 0, -1, true)
	local trun_config = get_config()
	trun_config[cwd] = table.concat(lines, "\n")

	Path:new(config):write(vim.fn.json_encode(trun_config), "w")
end

local function create_window()
	local width = 60
	local height = 10
	local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

	Bufnr = vim.api.nvim_create_buf(false, false)

	Win_id = popup.create(Bufnr, {
		title = "Trun",
		highlight = "TRunWindow",
		line = math.floor(((vim.o.lines - height) / 2) - 1),
		col = math.floor((vim.o.columns - width) / 2),
		minwidth = width,
		minheight = height,
		borderchars = borderchars,
	})
end

local function close_window()
	save()

	vim.api.nvim_win_close(Win_id, true)

	Win_id = nil
	Bufnr = nil
end

function M.run()
	local cmd = string.format("%s", get_cwd_config())
	tmux.sendCommand("2", cmd)
end

function M.toggle_trun_window()
	if Win_id ~= nil and vim.api.nvim_win_is_valid(Win_id) then
		close_window()
		return
	end

	create_window()

	local content = get_config()[cwd]
	local contents = utils.split(content, "\n")

	vim.api.nvim_set_option_value("number", true, { win = Win_id })
	vim.api.nvim_buf_set_lines(Bufnr, 0, #contents, false, contents)
	vim.api.nvim_set_option_value("filetype", "sh", { buf = Bufnr })
	vim.api.nvim_set_option_value("buftype", "acwrite", { buf = Bufnr })
	vim.api.nvim_set_option_value("bufhidden", "delete", { buf = Bufnr })

	vim.api.nvim_buf_set_keymap(Bufnr, "n", "q", "<cmd>lua require('trun').toggle_trun_window()<CR>", { silent = true })
	vim.api.nvim_buf_set_keymap(
		Bufnr,
		"n",
		"<esc>",
		"<cmd>lua require('trun').toggle_trun_window()<CR>",
		{ silent = true }
	)

	vim.cmd(string.format("autocmd BufModifiedSet <buffer=%s> set nomodified", Bufnr))
	vim.cmd("autocmd BufLeave <buffer> ++nested ++once silent lua require('trun').toggle_trun_window()")
end

function M.setup()
	vim.api.nvim_set_keymap("n", "<C-t>", "<cmd>lua require('trun').toggle_trun_window()<CR>", { silent = true })
	vim.api.nvim_set_keymap("n", "<C-c>", "<cmd>lua require('trun').run()<CR>", { silent = true })
end

return M
