local base = require('litcord.structures.base')

local Role = class(base)

function Role:__updated ()
	self.permissions = utils.Bitwise(
		self,
		self.permissions
	)
end

function Role:__updatedBitwise ()
	return self:setPermissions(self.permissions.value)
end

function Role:delete ()
	return self.parent.parent.rest:request(
		Route(
			'guilds/%s/roles/%s',
			self.parent.id,
			self.id
		),
		nil,
		'DELETE'
	)
end

function Role:edit (config)
	return self.parent.parent.rest:request(
		Route(
			'guilds/%s/roles/%s',
			self.parent.id,
			self.id
		),
		config,
		'PATCH'
	)
end
function Role:setName (name)
	return self:edit({
		name = name,
	})
end
function Role:setColor (color)
	return self:edit({
		color = color,
	})
end
function Role:setHoist (hoist)
	return self:edit({
		hoist = hoist,
	})
end
function Role:setPosition (position)
	return self:edit({
		position = position,
	})
end
function Role:setPermissions (permissions)
	return self:edit({
		permissions = permissions,
	})
end

return Role