local litcord = require('litcord')
local client = litcord.Client()

client:on(
	'ready',
	function()
		print('Ready!')
		client:setGame('litcord!')
	end
)

client:on(
	'message',
	function(message)
		print(message.author.username..': '..message.cleanContent)
	end
)

client:login(
	{
		--[[
		token = '',
		-- or both
		email = '',
		password = '',
		]]
	}
)