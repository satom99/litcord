local Server = class(structures.base)

function Server:__constructor ()
	self.roles = utils.Cache()
	self.members = utils.Cache()
	self.channels = utils.Cache()
end

function Server:__updated ()
	self.owner = self.parent.users:get('id', self.owner_id)
	self.afk_channel = self.channels:get('id', self.afk_channel_id)
	self.embed_channel = self.channels:get('id', self.embed_channel_id)
end

function Server:delete ()
	self.parent.rest:request(
		{
			method = 'DELETE',
			path = 'guilds/'..self.id,
		}
	)
end

function Server:edit (config)
	self.parent.rest:request(
		{
			method = 'PATCH',
			path = 'guilds/'..self.id,
			data = config,
		}
	)
end
function Server:setOwner (owner)
	owner = tonumber(owner) or owner.id
	self:edit({
		owner = owner,
	})
end
function Server:setName (name)
	self:edit({
		name = name,
	})
end
function Server:setIcon (icon)
	self:edit({
		icon = icon,
	})
end
function Server:setSplash (splash)
	self:edit({
		splash = splash,
	})
end
function Server:setRegion (region)
	self:edit({
		region = region,
	})
end
function Server:setAFKchannel (channel)
	channel = tonumber(channel) or channel.id
	self:edit({
		channel = channel,
	})
end
function Server:setAFKtimeout (timeout)
	self:edit({
		afk_timeout = timeout,
	})
end

function Server:createChannel (config)
	self.parent.rest:request(
		{
			method = 'POST',
			path = 'guilds/'..self.id..'/channels',
			data = config,
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
			bitrate = bitrate,
		}
	)
end

function Server:unban (user)
	user = tonumber(user) or user.id
	self.parent.rest:request(
		{
			method = 'DELETE',
			path = 'guild/'..self.id..'/bans/'..user,
		}
	)
end

function Server:getBans ()
	if not self.bans then
		local bans = self.parent.rest:request(
			{
				method = 'GET',
				path = 'guilds/'..self.id..'/bans',
			}
		)
		if not bans then return end
		self.bans = utils.Cache()
		for _,data in ipairs(bans) do
			local user = self.parent.users:get('id', data.id)
			if not user then
				users = structures.User(self)
				self.parent.users:add(user)
			end
			user:update(data)
			self.bans:add(user)
		end
	end
	return self.bans
end

function Server:getInvites ()
	if not self.invites then
		local invites = self.parent.rest:request(
			{
				method = 'GET',
				path = 'guilds/'..self.id..'/invites',
			}
		)
		if not invites then return end
		self.invites = utils.Cache('code')
		for _,v in ipairs(invites) do
			local channel = self.channels:get('id', v.channel.id)
			if channel then
				channel.invites = channel.invites or utils.Cache('code')
				local invite = structures.Invite(channel)
				v.guild = nil
				v.channel = nil
				v.inviter = nil
				invite:update(v)
				self.invites:add(invite)
				channel.invites:add(invite)
			end
		end
	end
	return self.invites
end

return Server