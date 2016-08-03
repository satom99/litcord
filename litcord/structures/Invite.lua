local Invite = class(structures.base)

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
	self.parent.invites:remove(self) -- channel
	self.parent.parent.invites:remove(self) -- server
end

return Invite