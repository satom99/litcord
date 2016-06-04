local classes = require('../classes')
local base = require('./base')

local Permissions = require('./Permissions')

local Overwrite = classes.new(base)

function Overwrite:__constructor () -- .parent = channel / .parent = user/server / .parent = client
	self.permissions = Permissions(self)
end

function Overwrite:__onUpdate ()
	self.permissions:__update(self.allow)
	self.allow = nil
	self.deny = nil
end

function Overwrite:__updatedPermissions ()
	self.parent.parent.parent.rest:request(
		{
			method = 'PUT',
			path = 'channels/'..self.parent.id..'/permissions/'..self.id,
			data = {
				allow = self.permissions.allow,
				deny = self.permissions.deny,
			},
		}
	)
end

function Overwrite:delete ()
	self.parent.parent.parent.rest:request(
		{
			method = 'DELETE',
			path = 'channels/'..self.parent.id..'/permissions/'..self.id,
		}
	)
end

return Overwrite