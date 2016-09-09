local Channel = class(structures.base)

function Channel:__constructor ()
	self.history = utils.Cache()
end

function Channel:sendMessage (content, config)
	config = config or {}
	config.content = content
	local data = self.parent.parent.rest:request(
		{
			method = 'POST',
			path = 'channels/'..self.id..'/messages',
			data = config,
		}
	)
	if not data then return end
	local message = structures.Message(self)
	self.history:add(message)
	message:update(data)
	return message
end

function Channel:sendFile (file, content, config) -- multipart/form-data
	config = config or {}
	local handler = io.open(file, 'r')
	if handler then
		file = handler:read('*a')
		handler:close()
	end
	config.file = file
	return self:sendMessage(content, config)
end

function Channel:getHistory (limit, config)
	local data = self.parent.parent.rest:request(
		{
			method = 'GET',
			path = 'channels/'..self.id..'/messages',
			data = utils.merge(
				{
					limit = limit,
				},
				config
			),
		}
	)
	if not data then return end
	for i,v in ipairs(data) do
		local message = structures.Message(self)
		message:update(v)
		data[i] = message
	end
	return data
end

function Channel:delete ()
	self.parent.parent.rest:request(
		{
			method = 'DELETE',
			path = 'channels/'..self.id,
		}
	)
end

function Channel:edit (config)
	self.parent.parent.rest:request(
		{
			method = 'PATCH',
			path = 'channels/'..self.id,
			data = config, -- bugs
		}
	)
end
function Channel:setName (name)
	self:edit({
		name = name,
	})
end
function Channel:setTopic (topic)
	self:edit({
		topic = topic,
	})
end
function Channel:setSlots (slots)
	self:edit({
		slots = slots,
	})
end
function Channel:setBitrate (bitrate)
	self:edit({
		bitrate = bitrate,
	})
end
function Channel:setPosition (position)
	self:edit({
		position = position,
	})
end

function Channel:createInvite (config)
	local data = self.parent.parent.rest:request(
		{
			method = 'POST',
			path = 'channels/'..self.id..'/invites',
			data = config,
		}
	)
	if not data then return end
	local invites = self.parent:getInvites()
	local invite = invites:get('code', data.code)
	if not invite then
		invite = structures.Invite(self)
		self.invites:add(invite)
		self.parent.invites:add(invite)
	end
	invite:update(data)
	return invite
end

function Channel:getInvites()
	self.parent:getInvites()
	return self.invites
end

return Channel