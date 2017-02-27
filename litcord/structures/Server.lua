local base = require('litcord.structures.base')
local Role = require('litcord.structures.Role')
local User = require('litcord.structures.User')
local Invite = require('litcord.structures.Invite')
local Channel = require('litcord.structures.Channel')

local Server = class(base)

function Server:__constructor ()
	self.bans = utils.Cache()
	self.roles = utils.Cache()
	self.members = utils.Cache()
	self.channels = utils.Cache()
	self.invites = utils.Cache()
end

function Server:__updated ()
	self.owner = self.parent.users:get(self.owner_id) or self.owner_id
	self.afk_channel = self.channels:get(self.afk_channel_id)
	self.embed_channel = self.channels:get(self.embed_channel_id)
end

function Server:delete ()
	return self.parent.rest:request(
		Route(
			'guilds/%s',
			self.id
		),
		nil,
		'DELETE'
	)
end

function Server:edit (config)
	return self.parent.rest:request(
		Route(
			'guilds/%s',
			self.id
		),
		config,
		'PATCH'
	)
end
function Server:setOwner (owner)
	owner = owner.id or owner
	return self:edit({
		owner = owner,
	})
end
function Server:setName (name)
	return self:edit({
		name = name,
	})
end
function Server:setRegion (region)
	return self:edit({
		region = region,
	})
end
function Server:setIcon (icon)
	return self:edit({
		icon = icon,
	})
end
function Server:setSplash (splash)
	return self:edit({
		splash = splash,
	})
end
function Server:setAFKtimeout (timeout)
	return self:edit({
		afk_timeout = timeout,
	})
end
function Server:setAFKchannel (channel)
	channel = channel.id or channel
	return self:edit({
		channel = channel,
	})
end
function Server:setVerification (level)
	return self:edit({
		verification_level = level,
	})
end

function Server:createRole ()
	local data, err = self.parent.rest:request(
		Route(
			'guilds/%s/roles',
			self.id
		),
		{},
		'POST'
	)
	if not data then
		return data, err
	end
	local role = Role(self)
	role:update(data)
	self.roles:add(role)
	return role
end

function Server:createChannel (config)
	local data, err = self.parent.rest:request(
		Route(
			'guilds/%s/channels',
			self.id
		),
		config,
		'POST'
	)
	if not data then
		return data, err
	end
	local channel = Channel(self)
	channel:update(data)
	self.channels:add(channel)
	return channel
end
function Server:createTextChannel (name)
	return self:createChannel(
		{
			type = 'text',
			name = name,
		}
	)
end
function Server:createVoiceChannel (name, bitrate)
	return self:createChannel(
		{
			type = 'voice',
			name = name,
			bitrate = bitrate,
		}
	)
end

function Server:prune (days)
	return self.parent.rest:request(
		Route(
			'guilds/%s/prune',
			self.id
		),
		{
			days = days or 1,
		},
		'POST'
	)
end

function Server:unban (user)
	return self.parent.rest:request(
		Route(
			'guilds/%s/bans/%s',
			self.id,
			user.id or user
		),
		nil,
		'DELETE'
	)
end

function Server:getBans ()
	local data, err = self.parent.rest:request(
		Route(
			'guilds/%s/bans',
			self.id
		)
	)
	if not data then
		return data, err
	end
	self.bans = utils.Cache()
	for _,ban in ipairs(data) do
		local user = self.parent.users:get(ban.id)
		if not user then
			users = User(self)
			self.parent.users:add(user)
		end
		user:update(ban)
		self.bans:add(user)
	end
	return self.bans
end

function Server:getInvites ()
	local data, err = self.parent.rest:request(
		Route(
			'guilds/%s/invites',
			self.id
		)
	)
	if not data then
		return data, err
	end
	self.invites = utils.Cache('code')
	for _,invite in ipairs(data) do
		local channel = self.channels:get(invite.channel.id)
		if channel then
			local object = Invite(channel)
			invite.guild = nil
			invite.channel = nil
			object:update(invite)
			self.invites:add(object)
			channel.invites = channel.invites or utils.Cache('code')
			channel.invites:add(object)
		end
	end
	return self.invites
end

return Server