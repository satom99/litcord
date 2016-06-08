local class = require('../classes/new')
local base = require('./base')

local Invite = class(base)

function Invite:__onUpdate ()
	self.channel = self.parent
	self.server = self.parent.parent
end

function Invite:accept ()
	self.parent.parent.rest:request(
		{
			method = 'POST',
			path = 'invites/'..self.code,
		}
	)
end

function Invite:delete ()
	local success = self.parent.parent.rest:request(
		{
			method = 'DELETE',
			path = 'invites/'..self.code,
		}
	)
	if not success then return end
	self.server.invites:remove(self)
	self.channel.invites:remove(self)
end

return Invite