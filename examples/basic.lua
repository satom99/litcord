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
		local mentioned
		for _,v in ipairs(message.mentions) do
			if v.id == client.user.id then
				mentioned = true
			end
		end
		if not mentioned then return end
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