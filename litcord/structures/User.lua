local classes = require('../classes')
local base = require('./base')

local Channel = require('./Channel')
local constants = require('../constants')

local User = classes.new(base)

function User:__constructor ()
	self.servers = classes.Cache()
end

function User:sendMessage (...)
	if not self.channel then
		local data = self.parent:request(
			{
				method = 'POST',
				path = constants.rest.ME_DMS,
				data = {
					recipient_id = self.id,
				},
			}
		)
		if not self.data then return end
		self.channel = Channel(self)
		self.channel:update(data)
		self.parent.__channels:add(self.channel)
	end
	self.channel:sendMessage(...)
end

return User