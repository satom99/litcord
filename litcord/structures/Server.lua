local classes = require('../classes')
local base = require('./base')

local User = require('./User')
local Role = require('./Role')
local Invite = require('./Invite')

local Server = classes.new(base)

function Server:__constructor ()
	self.bans = classes.Cache()
	self.roles = classes.Cache()
	self.members = classes.Cache()
	self.channels = classes.Cache()
	self.invites = classes.Cache('code')
end

function Server:__onUpdate ()
	self.owner = self.parent.users:get('id', self.owner_id)
	self.afk_channel = self.channels:get('id', self.afk_channel_id)
	self.embed_channel = self.channels:get('id', self.embed_channel_id)
end

function Server:modify (settings)
	self.parent.rest:request(
		{
			method = 'PATCH',
			path = 'guilds/'..self.id,
			data = settings,
		}
	)
end
function Server:setName (name)
	self:modify({name = name})
end
function Server:setRegion (region)
	self:modify({region = region})
end
function Server:setIcon (icon)
	self:modify({icon = icon})
end
function Server:setAFKchannel (channel)
	local id = channel
	if type(channel) == 'table' then
		id = channel.id
	end
	self:modify({channel = id})
end
function Server:setAFKtimeout (timeout)
	self:modify({afk_timeout = timeout})
end
function Server:setOwner (owner)
	local id = owner
	if type(owner) == 'table' then
		id = owner.id
	end
	self:modify({owner = id})
end
function Server:setSplash (splash)
	self:modify({splash = splash})
end

function Server:delete ()
	self.parent.rest:request(
		{
			method = 'DELETE',
			path = 'guilds/'..self.id,
		}
	)
end

function Server:unbanUser (user)
	local userID = user
	if type(user) == 'table' then
		userID = user.id
	end
	self.parent.rest:request(
		{
			method = 'DELETE',
			path = 'guild/'..self.id..'/bans/'..userID,
		}
	)
end

function Server:createChannel (settings)
	self.parent.rest:request(
		{
			method = 'POST',
			path = 'guilds/'..self.id..'/channels',
			data = settings,
		}
	)
end
function Server:createTextChannel (name)
	self:createChannel(
		{
			type = 'text',
			name = name,
		}
	)
end
function Server:createVoiceChannel (name, bitrate)
	self:createChannel(
		{
			type = 'voice',
			name = name,
			bitrate = bitrate or 96000,
		}
	)
end

function Server:getInvites ()
	if not self.__retrievedInvites then
		self.__retrievedInvites = true
		local invites = self.parent.rest:request(
			{
				method = 'GET',
				path = 'guilds/'..self.id..'/invites',
			}
		)
		for _,v in ipairs(invites) do
			local invite = self.invites:get('code', v.code)
			if not invite then
				local channel = self.channels:get('id', v.channel.id)
				if not channel then return end -- should exist, just making sure
				channel.__retrievedInvites = true
				invite = Invite(channel)
				self.invites:add(invite)
				channel.invites:add(invite)
			end
			v.guild = nil
			v.inviter = nil
			invite:update(v)
		end
	end
	return self.invites
end

function Server:getBans ()
	if not self.bans then
		local bans = self.parent.rest:request(
			{
				method = 'GET',
				path = 'guilds/'..self.id..'/bans',
			}
		)
		for _,v in ipairs(bans) do
			local user = self.parent.users:get('id', data.id)
			if not user then
				user = User(self)
				self.parent.users:add(user)
			end
			user:update(data)
			self.bans:add(user)
		end
	end
	return self.bans
end

function Server:createRole (config)
	local data = self.parent.rest:request(
		{
			method = 'POST',
			path = 'guilds/'..self.id..'/roles',
		}
	)
	local role = Role(self)
	self.roles:add(role)
	role:update(data)
	if config then
		role:edit(config)
	end
	return role
end

return Server