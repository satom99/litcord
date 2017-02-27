local litcord = require('litcord')
local tokens = {
	'123',
	'456',
	'789',
}

for _,token in ipairs(tokens) do
	local client = litcord(token)
	client:on(
		'ready',
		function()
			local user = client.user
			local servers = client.servers
			print(user.username..' is now running on '..#servers..' servers.')
		end
	)
end

litcord:run()