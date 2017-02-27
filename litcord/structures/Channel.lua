local base = require('litcord.structures.base')
local Invite = require('litcord.structures.Invite')
local Message = require('litcord.structures.Message')

local Channel = class(base)
Channel.type = {
	DM = 1,
	GROUP = 3,
	GUILD = 0,
	VOICE = 2,
}

function Channel:__constructor ()
	self.invites = utils.Cache()
	self.history = utils.Cache()
end

function Channel:__updated ()
	self.is_voice = not self.topic
	self.is_private = not self.parent.roles
end

function Channel:sendMessage (thing)
	if type(thing) ~= 'table' then
		thing = {
			content = thing,
		}
	end
	local data, err = self.parent.parent.rest:request(
		Route(
			'channels/%s/messages',
			self.id
		),
		thing,
		'POST'
	)
	if not data then
		return data, err
	end
	local message = Message(self)
	message:update(data)
	self.history:add(message)
	return message
end

-- sendFile

function Channel:getHistory (limit, config)
	config = config or {}
	config.limit = limit
	local data, err = self.parent.parent.rest:request(
		Route(
			'channels/%s/messages',
			self.id
		),
		config
	)
	if not data then
		return data, err
	end
	for _,v in ipairs(data) do
		local message = self.history:get(v.id)
		if not message then
			message = Message(self)
			self.history:add(message)
		end
		message:update(v)
	end
	return self.history
end

function Channel:bulkDelete (messages)
	for i,v in ipairs(messages) do
		messages[i] = v.id or v
	end
	return self.parent.parent.rest:request(
		Route(
			'channels/%s/messages/bulk_delete',
			self.id
		),
		{
			messages = messages,
		},
		'POST'
	)
end

function Channel:delete ()
	return self.parent.parent.rest:request(
		Route(
			'channels/%s',
			self.id
		),
		nil,
		'DELETE'	
	)
end

function Channel:edit (config)
	return self.parent.parent.rest:request(
		Route(
			'channels/%s',
			self.id
		),
		config,
		'PATCH'
	)
end
function Channel:setName (name)
	return self:edit({
		name = name,
	})
end
function Channel:setTopic (topic)
	return self:edit({
		topic = topic,
	})
end
function Channel:setBitrate (bitrate)
	return self:edit({
		bitrate = bitrate,
	})
end
function Channel:setPosition (position)
	return self:edit({
		position = position,
	})
end
function Channel:setSlots (slots)
	return self:edit({
		slots = slots,
	})
end

function Channel:createInvite (config)
	local data, err = self.parent.parent.rest:request(
		Route(
			'channels/%s/invites',
			self.id
		),
		config,
		'POST'
	)
	if not data then
		return data, err
	end
	local invite = Invite(self)
	invite:update(data)
	self.invites:add(invite)
	self.parent.invites:add(invite)
	return invite
end

function Channel:getInvites()
	self.parent:getInvites()
	return self.invites
end

return Channel