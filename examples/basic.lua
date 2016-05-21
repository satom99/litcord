local litcord = require('litcord')
local client = litcord.Client()

client:on(
	'ready',
	function()
		print('Ready!')
	end
)

client:on(
	'message',
	function(message)
		print(message.author.username..': '..message.cleanContent)
	end
)

client:on(
	'message',
	function(message)
		if message.author.id == client.user.id then return end
		if not message.client_mentioned then return end
		message:reply('interesting..')
	end
)

client:login(
	{
		--[[
		token = '',
		-- or --
		email = '',
		password = '',
		]]
	}
)