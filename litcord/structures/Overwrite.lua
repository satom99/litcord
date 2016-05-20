local classes = require('../classes')
local base = require('./base')

local Permissions = require('./Permissions')

local Overwrite = classes.new(base)

function Overwrite:__constructor () -- .parent = channel / .parent = user/server / .parent = client
	self.permissions = Permissions(self, self.allow)
end

function Overwrite:delete ()
	self.parent.parent.parent.rest:request(
		{
			method = 'DELETE',
			path = 'channels/'..self.parent.id..'/permissions/'..self.id,
		}
	)
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

return Overwrite