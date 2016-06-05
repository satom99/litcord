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
	self.parent.parent.rest:request(
		{
			method = 'DELETE',
			path = 'invites/'..self.code,
		}
	)
end

return Invite