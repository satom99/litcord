local User = class(structures.base)

function User:__constructor ()
	self.servers = utils.Cache()
end

function User:sendMessage (...)
	if not self.channel then
		local channel = self.parent.rest:request(
			{
				method = 'POST',
				path = constants.rest.ME_DMS,
				data = {
					recipient_id = self.id,
				},
			}
		)
		if not channel then return end
		channel = structures.Channel(self)
		channel:update(data)
		self.parent.channels:add(channel)
	end
	return self.channel:sendMessage(...)
end

return User