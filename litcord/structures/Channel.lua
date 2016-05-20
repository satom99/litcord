local classes = require('../classes')
local base = require('./base')

local constants = require('../constants')

local Invite = require('./Invite')
local Message = require('./Message')
local VoiceConnection = require('./VoiceConnection')

local Channel = classes.new(base)

function Channel:__constructor ()
	self.history = classes.Cache()
end

function Channel:__onUpdate ()
	self.isVoice = (not self.topic and not self.last_message_id)
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
	local message = Message(self, self.parent.parent.user)
	self.history:add(message)
	message:update(data)
	return message
end

function Channel:getInvites()
	if not self.invites then
		self.invites = classes.Cache()
		local invites = self.parent.rest:request(
			{
				method = 'GET',
				path = 'channels/'..self.id..'/invites',
			}
		)
		for _,v in ipairs(invites) do
			v.inviter = nil
			local invite = Invite(self)
			invite:update(v)
			self.invites:add(invite)
		end
	end
	return self.invites
end

-- Voice
function Channel:join ()
	if not self.isVoice or self.voiceConnection then return end
	self.voiceConnection = VoiceConnection(self)
end

function Channel:leave ()
	if not self.isVoice or not self.voiceConnection then return end
	print('leave')
	self.voiceConnection:disconnect()
end

return Channel