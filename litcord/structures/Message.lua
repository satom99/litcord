local base = require('litcord.structures.base')
local Reaction = require('litcord.structures.Reaction')

local Message = class(base)

function Message:__constructor ()
	self.reactions = utils.Cache()
end

function Message:__updated ()
	self.clean = self.content
	if not self.mentions then
		return
	end
	for i,user in ipairs(self.mentions) do
		self.mentions[i] = self.parent.parent.parent.users:get('id', user.id)
		self.clean = self.clean:gsub('<@'..user.id..'>', '@'..user.username)
		self.clean = self.clean:gsub('<@!'..user.id..'>', '@!'..user.username)
		if user.id == self.parent.parent.parent.user.id then
			self.mentions.client = true
		end
	end
	for mention in self.clean:gmatch('<#.->') do
		local snowflake = mention:sub(3, #mention - 1)
		local channel = self.parent.parent.parent.channels:get(snowflake)
		local name = (channel and channel.name) or snowflake
		self.clean = self.clean:gsub(mention, '#'..name)
	end
	for mention in self.content:gmatch('<@&.->') do
		local snowflake = mention:sub(4, #mention - 1)
		local role = self.parent.parent.roles:get(snowflake)
		local name = (role and role.name) or snowflake
		self.clean = self.clean:gsub(mention, '@'..name)
	end
end

function Message:react (emoji)
	local data, err = self.parent.parent.parent.rest:request(
		Route(
			'channels/%s/messages/%s/reactions/%s/@me',
			self.parent.id,
			self.id,
			emoji.id or emoji
		),
		nil,
		'PUT'
	)
	if not data then
		return data, err
	end
	local reaction = Reaction(self)
	reaction:update(data.emoji)
	self.reactions:add(reaction)
	return reaction
end

function Message:reply (thing)
	if not self.parent.is_private then
		local prepend = '<@!'..self.author.id..'> '
		if type(thing) == 'table' then
			thing.content = prepend .. thing.content
		else
			thing = prepend .. thing
		end
	end
	return self.parent:sendMessage(thing)
end

function Message:delete ()
	return self.parent.parent.parent.rest:request(
		Route(
			'channels/%s/messages/%s',
			self.parent.id,
			self.id
		),
		nil,
		'DELETE'	
	)
end

function Message:edit (thing)
	if type(thing) ~= 'table' then
		thing = {
			content = thing,
		}
	end
	return self.parent.parent.parent.rest:request(
		Route(
			'channels/%s/messages/%s',
			self.parent.id,
			self.id
		),
		thing,
		'PATCH'
	)
end

return Message