package.path = './?/init.lua;' .. package.path

local litcord = require('litcord')
local client = litcord()

client:on(
	'messageCreate',
	function(message)
		print(message.author.username..': '..message.content_clean)
	end
)

client:login('token')