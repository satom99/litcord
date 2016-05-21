local class = require('../classes/new')
local base = require('./base')

local Message = class(base) -- parent = channel / channel.parent = user/server / x.parent = client |=> .parent.parent.parent equals to client

function Message:__constructor (_, author)
	self.author = author
	self.channel = self.parent
end

function Message:__onUpdate ()
	self.cleanContent = self.content
	for _,v in ipairs(self.mentions) do
		self.cleanContent = self.cleanContent:gsub('<@'..v.id..'>', '@'..v.username)
		self.cleanContent = self.cleanContent:gsub('<@!'..v.id..'>', '@!'..v.username)
	end
	for mention in self.content:gmatch('<#.->') do -- channel mentions
		local id = mention:sub(3, #mention-1)
		local channel = self.parent.parent.channels:get('id', id)
		local name = (channel and channel.name) or id
		self.cleanContent = self.cleanContent:gsub(mention, '#'..name)
	end
	for mention in self.content:gmatch('<@&.->') do -- role mentions
		local id = mention:sub(4, #mention-1)
		local role = self.parent.parent.roles:get('id', id)
		local name = (role and role.name) or id
		self.cleanContent = self.cleanContent:gsub(mention, '@'..name)
	end
end

function Message:reply (content)
	if not self.parent.is_private then
		content = '<@!'..self.author.id..'> '..content
	end
	return self.parent:sendMessage(content)
end

function Message:edit (content)
	self.parent.parent.parent.rest:request(
		{
			method = 'PATCH',
			path = 'channels/'..self.parent.id..'/messages/'..self.id,
			data = {
				content = content,
			},
		}
	)
end

function Message:delete ()
	self.parent.parent.parent.rest:request(
		{
			method = 'DELETE',
			path = 'channels/'..self.parent.id..'/messages/'..self.id,
		}
	)
end

return Message