local class = require('../classes/new')
local base = require('./base')

local Role = class(base)

function Role:edit (config)
	self.parent.parent.rest:request(
		{
			method = 'PATCH',
			path = 'guilds/'..self.parent.id..'/roles/'..self.id,
			data = { -- config, -- gives an internal error, so no config directly..
				name = config.name or self.name,
				permissions = config.permissions or self.permissions.value,
				position = config.position or self.position,
				color = config.color or self.color,
				hoist = config.hoist or self.hoist,
			},
		}
	)
end
function Role:setName (name)
	self:edit({name = name})
end
function Role:setPermissions (bitwise)
	self:edit({permissions = bitwise})
end
function Role:setPosition (position)
	self:edit({position = position})
end
function Role:setColor (color)
	self:edit({color = color})
end
function Role:setHoist (hoist)
	self:edit({hoist = hoist})
end

function Role:__updatedPermissions ()
	self:setPermissions(self.permissions.allow)
end

return Role