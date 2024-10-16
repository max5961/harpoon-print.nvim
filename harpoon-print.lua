-- https://github.com/ThePrimeagen/harpoon
-- quickly add, delete, and move between files in a buffer

local M = {}

-- These are added in the config function
-- M.mark = require("harpoon.mark")
-- M.ui = require("harpoon.ui")

-- filename -> number -> radio
M.messageType = "filename"

M.leftBracket = "⟨"
M.rightBracket = "⟩"

-- M.leftBracket = "►"
-- M.rightBracket = " "

-- M.leftBracket = "╱"
-- M.rightBracket = "╲"

-- M.leftBracket = "❲"
-- M.rightBracket = "❳"

-- M.leftBracket = "❨"
-- M.rightBracket = "❩➤"

-- M.leftBracket = "➤"
-- M.rightBracket = " "

M.getBufferNumber = function()
	local buffer = vim.fn.getwininfo().bufnr
	return buffer
end

-- This only works when removing the last index, otherwise leaves an (empty) value
-- Commented out key mapping
M.removeFile = function()
	local buffer = M.getBufferNumber()
	local fileName = M.mark.get_marked_file_name(buffer)
	M.mark.rm_file(fileName)
	M.switchedMsg(-1, false)
end

-- Show the file name or the harpoon buffer idx
M.toggleMessageType = function()
	if M.messageType == "filename" then
		M.messageType = "number"
	elseif M.messageType == "number" then
		M.messageType = "radio"
	else
		M.messageType = "filename"
	end

	local num = M.mark.get_current_index()
	M.switchedMsg(num, false)
end

M.basename = function(filePath)
	local last = ""

	for i = 1, #filePath do
		local char = filePath:sub(i, i)
		if char == "/" then
			last = ""
		else
			last = last .. char
		end
	end

	return last
end

M.printBaseNameMsg = function(str, num)
	str = str.sub(str, 1, str.len(str) - 1)

	for idx = 1, M.mark.get_length() do
		local filePath = M.mark.get_marked_file_name(idx)
		local basename = M.basename(filePath)

		local startDelin = "|"
		if idx == 1 then
			startDelin = ""
		end

		if idx == num then
			str = str .. startDelin .. " " .. M.leftBracket .. "" .. basename .. "" .. M.rightBracket .. " "
		else
			str = str .. startDelin .. "  " .. basename .. "  "
		end
	end

	print(str)
end

M.printRadioMessage = function(str, num)
	str = str.sub(str, 1, str.len(str) - 1)

	for idx = 1, M.mark.get_length() do
		if idx == num then
			str = str .. " 🌑 "
		else
			str = str .. " 🌕 "
		end
	end
	print(str)
end

M.printNumberMessage = function(str, num)
	for idx = 1, M.mark.get_length() do
		if idx == num then
			str = str .. M.leftBracket .. idx .. M.rightBracket
		else
			str = str .. " " .. idx .. " "
		end
	end
	print(str)
end

M.switchedMsg = function(num, invalid)
	if invalid == true then
		print("Invalid buf: " .. num)
		return
	end

	local str = "buf: "

	if M.mark.get_length() == 0 then
		print(str .. "There are no Harpoon bufs")
		return
	end

	if M.messageType == "filename" then
		M.printBaseNameMsg(str, num)
	elseif M.messageType == "number" then
		M.printNumberMessage(str, num)
	else
		M.printRadioMessage(str, num)
	end
end

M.wrapper = function(cb)
	local buffer = vim.api.nvim_get_option_value("buftype", { buf = vim.fn.getwininfo().bufnr })

	if buffer ~= "terminal" then
		cb()
		return true
	else
		print("Harpoon doesn't work well with terminal buffers")
		return false
	end
end

M.switchWrapper = function(cb)
	if M.wrapper(cb) then
		M.switchedMsg(M.mark.get_current_index())
	end
end

M.addFile = function()
	M.wrapper(function()
		M.mark.add_file()
		print("File added to Harpoon menu " .. "(" .. M.mark.get_length() .. " bufs)")
	end)
end

M.toggleQuickMenu = function()
	M.wrapper(M.ui.toggle_quick_menu)
end

M.navNext = function()
	M.switchWrapper(function()
		M.wrapper(M.ui.nav_next)
	end)
end

M.navPrev = function()
	M.switchWrapper(function()
		M.wrapper(M.ui.nav_prev)
	end)
end

M.navBufNum = function(num)
	return function()
		M.wrapper(function()
			if M.mark.valid_index(num) then
				M.ui.nav_file(num)
				M.switchedMsg(num, false)
			else
				M.switchedMsg(num, true)
			end
		end)
	end
end

return {
	"ThePrimeagen/harpoon",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local mark = require("harpoon.mark")
		local ui = require("harpoon.ui")

		M.mark = mark
		M.ui = ui

		vim.keymap.set("n", "<leader>a", M.addFile)
		vim.keymap.set("n", "<leader>e", M.toggleQuickMenu)
		vim.keymap.set("n", "<A-n>", M.navNext)
		vim.keymap.set("n", "<A-p>", M.navPrev)
		vim.keymap.set("n", "<leader>1", M.navBufNum(1))
		vim.keymap.set("n", "<leader>2", M.navBufNum(2))
		vim.keymap.set("n", "<leader>3", M.navBufNum(3))
		vim.keymap.set("n", "<leader>4", M.navBufNum(4))
		vim.keymap.set("n", "<leader>5", M.navBufNum(5))
		vim.keymap.set("n", "<leader>6", M.navBufNum(6))
		vim.keymap.set("n", "<leader>b", M.toggleMessageType)
		-- vim.keymap.set("n", "<leader>g", M.removeFile)
	end,
}
