local class = require('../classes/new')
local base = require('./base')

local Invite = class(base)

function Invite:__constructor ()
	self.__client = self.parent.parent -- server
	if not self.__client.rest then -- channel
		self.__client = self.__client.parent
	end
end

function Invite:accept ()
	self.__client.rest:request(
		{
			method = 'POST',
			path = 'invites/'..self.code,
		}
	)
end

function Invite:delete ()
	self.__client.rest:request(
		{
			method = 'DELETE',
			path = 'invites/'..self.code,
		}
	)
end

return Invite