local Emoji = require('litcord.structures.Emoji')

local Reaction = class(Emoji)

function Reaction:__constructor ()
	self.users = utils.Cache()
end

function Reaction:sum (user)
	self.users:add(user)
end
function Reaction:lower (user)
	self.users:remove(user)
	if #self.users < 1 then
		self:remove()
	else
		self:remove(user)
	end
end

function Reaction:clear ()
	return self:remove()
end
function Reaction:remove (user)
	local route = 'channels/%s/messages/%s/reactions/%s'
	if user then
		user = user.id or user
		route = route..'/'..user
	end
	return self.parent.parent.parent.parent.rest:request(
		Route(
			route,
			self.parent.parent.id,
			self.parent.id,
			self.id
		),
		nil,
		'DELETE'
	)
end

return Reaction