local base = require('litcord.structures.base')

local Invite = class(base)

function Invite:__updated ()
	self.url = 'https://discord.gg/'..self.code
end

function Invite:accept ()
	return self.parent.parent.rest:request(
		Route(
			'invites/%s',
			self.code
		),		
		nil,
		'POST'
	)
end

function Invite:delete ()
	local data, err = self.parent.parent.rest:request(
		Route(
			'invites/%s',
			self.code
		),
		nil,
		'DELETE'
	)
	if not data then
		return data, err
	end
	self.parent.invites:remove(self)
	self.parent.parent.invites:remove(self)
end

return Invite