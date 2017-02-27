local base = require('litcord.structures.base')

local Overwrite = class(base)

function Overwrite:__updated ()
	self.deny = utils.Bitwise(
		self,
		self.deny
	)
	self.allow = utils.Bitwise(
		self,
		self.allow
	)
end

function Overwrite:__updatedBitwise ()
	return self.parent.parent.parent.rest:request(
		Route(
			'channels/%s/permissions/%s',
			self.parent.id,
			self.id
		),
		{
			deny = self.deny.value,
			allow = self.allow.value,
		},
		'PUT'
	)
end

function Overwrite:delete ()
	return self.parent.parent.parent.rest:request(
		Route(
			'channels/%s/permissions/%s',
			self.parent.id,
			self.id
		),
		nil,
		'DELETE'
	)
end

return Overwrite