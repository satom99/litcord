local Role = class(structures.base)

function Role:__updated ()
	self.permissions = utils.Bitwise(
		self,
		self.permissions
	)
end

function Role:__updatedBitwise ()
	self:setPermissions(self.permissions.value)
end

function Role:edit (config)
	self.parent.parent.rest:request(
		{
			method = 'PATCH',
			path = 'guilds/'..self.parent.id..'/roles/'..self.id,
			data = config, -- bugs
		}
	)
end
function Role:setName (name)
	self:edit({
		name = name,
	})
end
function Role:setColor (color)
	self:edit({
		color = color,
	})
end
function Role:setHoist (hoist)
	self:edit({
		hoist = hoist,
	})
end
function Role:setPosition (position)
	self:edit({
		position = position,
	})
end
function Role:setPermissions (permissions)
	self:edit({
		permissions = permissions,
	})
end

return Role