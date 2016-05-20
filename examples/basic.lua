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
		if message.author.id == 0 then -- change this with your id
			message:reply('interesting..')
		end
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