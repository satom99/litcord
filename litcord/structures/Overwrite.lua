local Overwrite = class(structures.base)

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
	self.parent.parent.parent.rest:request(
		{
			method = 'PUT',
			path = 'channels/'..self.parent.id..'/permissions/'..self.id,
			data = {
				deny = self.deny.value,
				allow = self.allow.value,
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