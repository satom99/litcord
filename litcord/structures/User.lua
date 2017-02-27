local base = require('litcord.structures.base')
local Channel = require('litcord.structures.Channel')

local User = class(base)

function User:__constructor ()
	self.servers = utils.Cache()
end

function User:sendMessage (...)
	if not self.channel then
		local data, err = self.parent.rest:request(
			Route(
				'users/@me/channels'
			),
			{
				recipient_id = self.id,
			},
			'POST'
		)
		if not data then
			return data, err
		end
		local channel = Channel(self)
		channel:update(data)
		self.parent.channels:add(channel)
		self.channel = channel
	end
	return self.channel:sendMessage(...)
end

return User