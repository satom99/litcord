local litcord = require('litcord')
local client = litcord('token')

client:on(
	'messageCreate',
	function(message)
		local author = message.author
		print(author.username..': '..message.clean)
	end
)

litcord:run()