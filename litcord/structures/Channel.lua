local utils = require('../utils')
local classes = require('../classes')
local base = require('./base')

local Invite = require('./Invite')
local Message = require('./Message')
local VoiceConnection = require('./VoiceConnection')

local Channel = classes.new(base)

function Channel:__constructor ()
	self.history = classes.Cache()
	self.invites = classes.Cache('code')
end

function Channel:__onUpdate ()
	self.isVoice = (not self.topic and not self.last_message_id)
end

function Channel:sendFile (file, content, options)
	options = options or {}
	options.file = file
	return self:sendMessage(content, options)
end

function Channel:sendMessage (content, options)
	options = options or {}
	options.content = content
	local data = self.parent.parent.rest:request(
		{
			method = 'POST',
			path = 'channels/'..self.id..'/messages',
			data = options,
		}
	)
	if not data then return end
	local message = Message(self, self.parent.parent.user)
	self.history:add(message)
	message:update(data)
	return message
end

function Channel:createInvite (config)
	local data = self.parent.parent.rest:request(
		{
			method = 'POST',
			path = 'channels/'..self.id..'/invites',
			data = config,
		}
	)
	local invite = Invite(self)
	invite:update(data)
	self.invites:add(invite)
	return invite
end

function Channel:getInvites()
	if not self.__retrievedInvites then
		self.__retrievedInvites = true
		local invites = self.parent.rest:request(
			{
				method = 'GET',
				path = 'channels/'..self.id..'/invites',
			}
		)
		for _,v in ipairs(invites) do
			v.guild = nil
			v.inviter = nil
			local invite = Invite(self)
			invite:update(v)
			self.invites:add(invite)
			self.parent.invites:add(invite)
		end
	end
	return self.invites
end

function Channel:delete ()
	self.parent.parent.rest:request(
		{
			method = 'DELETE',
			path = 'channels/'..self.id,
		}
	)
end

function Channel:modify (config)
	self.parent.parent.rest:request(
		{
			method = 'PATCH',
			path = 'channels/'..self.id,
			data = utils.merge(
				config,
				{
					name = config.name or self.name,
					position = config.position or self.position,
					topic = config.topic or self.topic,
					bitrate = config.bitrate or self.bitrate,
					user_limit = config.user_limit or self.user_limit,
				}
			)
		}
	)
end
function Channel:setName (name)
	self:modify({name = name})
end
function Channel:setPosition (position)
	self:modify({position = position})
end
function Channel:setTopic (topic)
	self:modify({topic = topic})
end
function Channel:setBitrate (bitrate)
	self:modify({bitrate = bitrate})
end
function Channel:setSlots (slots)
	self:modify({user_limit = slots})
end

-- Voice
function Channel:join ()
	if not self.isVoice then return end
	if not self.parent.__voiceConnection then
		self.parent.__voiceConnection = VoiceConnection(self.parent)
	end
	self.parent.__voiceConnection:connect(self.id)
end

function Channel:leave ()
	if not self.isVoice or (self.parent.__voiceConnection.channel_id ~= self.id) then return end
	self.parent.__voiceConnection:disconnect()
end

return Channel