local Rest = require('litcord.client.Rest')
local Socket = require('litcord.client.Socket')
local Routiner = require('litcord.client.Routiner')
local structures = require('litcord.structures')

local clock = require('cqueues').monotime

local Client = class(utils.Events)
Client.events = {}
for k,v in pairs(Socket.events) do -- camelCase
	Client.events[k] = v:gsub(
		'%W%l',
		string.upper
	):gsub('_', '')
end
Client.id = 0
Client.routiner = Routiner()

function Client:run ()
	while true do
		Client.routiner:process()
	end
end

function Client:__constructor (token, shard)
	self.token = token
	self.settings = {}
	--
	self.users = utils.Cache()
	self.servers = utils.Cache()
	self.channels = utils.Cache()
	--
	self.rest = Rest(self)	
	self.socket = Socket(self)
	self.coroutine = coroutine.create(
		function()
			coroutine.yield()
			self.socket:run()
			while true do
				self.socket:process()
			end
		end
	)
	Client.routiner:add(self.coroutine)
	--
	if not shard then
		self:__sharding()
	end
	self:__initHandlers()
end

function Client:__sharding ()
	local data = self.rest:request(
		Route(
			'gateway/bot'
		)
	)
	if not data then
		return
	end
	local count = data.shards
	if count > 1 then
		self.settings.shard = {
			0,
			count		
		}
		for index = 1, (count - 1) do
			local shard = Client(
				self.token,
				true			
			)
			shard.settings.shard = {
				index,
				count
			}
			shard.id = index
			shard.rest = self.rest
			shard.users = self.users
			shard.servers = self.servers
			shard.channels = self.channels
			shard._handlers = self._handlers
		end
	end
	self.__sharding = nil
end

function Client:__initHandlers ()
	self.socket:on(
		Socket.events.READY,
		function(data)
			self.user = structures.User(self)
			self.user:update(data.user)
			self.users:add(self.user)
			for _,guild in ipairs(data.guilds) do
				self.socket:emit(
					Socket.events.GUILD_CREATE,
					guild
				)
			end
			for _,channel in ipairs(data.private_channels) do
				self.socket:emit(
					Socket.events.CHANNEL_CREATE,
					channel
				)
			end
			print('* '..self.user.username..' ready.', self.id)
		end
	)
	--
	self.socket:on(
		Socket.events.USER_UPDATE,
		function(data)
			local user = self.users:get(data.id)
			if not user then
				user = structures.User(self)
				self.users:add(user)
			end
			user:update(data)
		end
	)
	--
	self.socket:on(
		{
			Socket.events.CHANNEL_CREATE,
			Socket.events.CHANNEL_UPDATE,
		},
		function(data)
			if not data.guild_id then
				local recipients = utils.Cache()
				for _,user in ipairs(data.recipients) do
					local recipient = self.users:get(user.id)
					if not recipient then
						recipient = structures.User(self)
						self.users:add(recipient)
					end
					recipient:update(user)
					recipients:add(recipient)
				end
				--
				local parent = recipients[1]
				local channel = self.channels:get(data.id)
				if not channel then
					channel = structures.Channel(parent)
					self.channels:add(channel)
				end
				channel.recipients = recipients
				channel:update(data)
				--
				if data.type == structures.Channel.type.DM then
					parent.channel = channel
				end
			else
				local server = self.servers:get(data.guild_id)
				if not server then return end
				local overwrites = data.permission_overwrites or {}
				data.permission_overwrites = nil
				data.guild_id = nil
				local channel = server.channels:get(data.id)
				if not channel then
					channel = structures.Channel(server)
					self.channels:add(channel)
					server.channels:add(channel)
				end
				channel:update(data)
				--
				channel.overwrites = utils.Cache()
				for _,v in ipairs(overwrites) do
					local overwrite = structures.Overwrite(channel)
					channel.overwrites:add(overwrite)
					overwrite:update(v)
				end
			end
		end
	)
	self.socket:on(
		Socket.events.CHANNEL_DELETE,
		function(data)
			local types = structures.Channel.type
			local channel = self.channels:get(data.id)
			if not channel then
				return
			elseif channel.type == types.DM then
				channel.parent.channel = nil
			elseif channel.type ~= types.GROUP then
				channel.parent.channels:remove(channel)
			end
			self.channels:remove(channel)
		end
	)
	--
	self.socket:on(
		{
			Socket.events.MESSAGE_CREATE,
			Socket.events.MESSAGE_UPDATE,
		},
		function(data)
			local channel = self.channels:get(data.channel_id)
			if not channel then return end
			local message = channel.history:get(data.id)
			if not message then
				if data.author then
					local author = self.users:get(data.author.id)
					if not author then
						author = structures.User(self)
						self.users:add(author)
					end
					author:update(data.author)
					data.author = author
				end
				message = structures.Message(channel)
				channel.history:add(message)
			end
			message:update(data)
		end
	)
	self.socket:on(
		Socket.events.MESSAGE_DELETE,
		function(data)
			local channel = self.channels:get(data.channel_id)
			if not channel then return end
			channel.history:remove(data.id)
			self:emit(
				Client.events.MESSAGE_DELETE,
				data.id
			)
		end
	)
	self.socket:on(
		Socket.events.MESSAGE_DELETE_BULK,
		function(data)
			local channel = self.channels:get(data.channel_id)
			if not channel then return end
			for _,id in ipairs(data.ids) do
				channel.history:remove(id)
				self:emit(
					Client.events.MESSAGE_DELETE,
					id
				)
			end
		end
	)
	self.socket:on(
		Socket.events.MESSAGE_REACTION_ADD,
		function(data)
			local user = self.users:get(data.user_id)
			if not user then return end
			local channel = self.channels:get(data.channel_id)
			if not channel then return end
			local message = channel.history:get(data.message_id)
			if not message then return end
			local reaction = message.reactions:get(data.emoji.id)
			if not reaction then
				reaction = structures.Reaction(message)
				message.reactions:add(reaction)
			end
			reaction:update(data.emoji)
			reaction:sum(user)
		end
	)
	self.socket:on(
		Socket.events.MESSAGE_REACTION_REMOVE,
		function(data)
			local channel = self.channels:get(data.channel_id)
			if not channel then return end
			local message = channel.history:get(data.message_id)
			if not message then return end
			local reaction = message.reactions:get(data.emoji.id)
			if not reaction then return end
			reaction:update(data.emoji)
			reaction:lower(data.user_id)
		end
	)
	--
	self.socket:on(
		{
			Socket.events.GUILD_CREATE,
			Socket.events.GUILD_UPDATE,
		},
		function(data)
			local roles = data.roles or {}
			local members = data.members or {}
			local channels = data.channels or {}
			data.roles = nil
			data.members = nil
			data.channels = nil
			--
			local sum = #roles + #members + #channels
			local time = sum / 10^3
			local warning = (time > 3)
			if warning then
				print('* Parsing, please allow up to '..time..' seconds', self.id)
			end
			--
			local server = self.servers:get(data.id)
			if not server then
				server = structures.Server(self)
				self.servers:add(server)
			end
			server:update(data)
			for _,role in ipairs(roles) do
				self.socket:emit(
					Socket.events.GUILD_ROLE_CREATE,
					{
						role = role,
						guild_id = data.id,
					}
				)
			end
			for i,member in ipairs(members) do
				member.guild_id = data.id
				self.socket:emit(
					Socket.events.GUILD_MEMBER_ADD,
					member
				)
			end
			for _,channel in ipairs(channels) do
				channel.guild_id = data.id
				self.socket:emit(
					Socket.events.CHANNEL_CREATE,
					channel
				)
			end
			--
			if warning then
				print('* Done parsing.', self.id)
			end
		end
	)
	self.socket:on(
		Socket.events.GUILD_DELETE,
		function(data)
			local server = self.servers:get(data.id)
			if not server then return end
			for _,member in ipairs(server.members) do
				self.socket:emit(
					Socket.events.GUILD_MEMBER_REMOVE,
					{
						user = member.user,
						guild_id = data.id,
					}
				)
			end
			self.servers:remove(server)
		end		
	)
	--
	self.socket:on(
		{
			Socket.events.GUILD_ROLE_CREATE,
			Socket.events.GUILD_ROLE_UPDATE,
		},
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local role = server.roles:get(data.role.id)
			if not role then
				role = structures.Role(server)
				server.roles:add(role)
			end
			role:update(data.role)
		end
	)
	self.socket:on(
		Socket.events.GUILD_ROLE_DELETE,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			server.roles:remove(data.role_id)
		end
	)
	--
	self.socket:on(
		{
			Socket.events.PRESENCE_UPDATE,
			Socket.events.GUILD_MEMBER_ADD,
			Socket.events.GUILD_MEMBER_UPDATE,
		},
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local user = self.users:get(data.user.id)
			if not user then
				user = structures.User(self)
				self.users:add(user)
			end
			user:update(data.user)
			user.servers:add(server)
			--
			local member = server.members:get(user.id)
			if not member then
				member = structures.Member(server)
				server.members:add(member)
			end
			data.id = user.id
			data.user = user
			member:update(data)
		end
	)
	self.socket:on(
		Socket.events.GUILD_MEMBERS_CHUNK,
		function(data)
			for _,member in ipairs(data.members) do
				member.guild_id = data.guild_id
				self.socket:emit(
					Socket.events.GUILD_MEMBER_ADD,
					member
				)
			end
		end	
	)
	self.socket:on(
		Socket.events.GUILD_MEMBER_REMOVE,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local user = self.users:get(data.user.id)
			if not user then return end
			user.servers:remove(server)
			server.members:remove(user)
			if #user.servers < 1 then
				self.users:remove(user)
			end
		end	
	)
	--
	self.socket:on(
		Socket.events.GUILD_BAN_ADD,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local user = self.users:get(data.id)
			if not user then
				user = structures.User(self)
				self.users:add(user)
			end
			user:update(data)
			server.bans:add(user)
		end
	)
	self.socket:on(
		Socket.events.GUILD_BAN_REMOVE,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local ban = server.bans:get(data.id)
			if not ban then return end
			server.bans:remove(ban)
		end
	)
	--
	self:__wrappedHandlers()
	self.__initHandlers = nil
end

function Client:__wrappedHandlers ()
	self.socket:on(
		Socket.events.READY,
		function()
			self:emit(
				Client.events.READY
			)
		end
	)
	--
	self.socket:on(
		Socket.events.CHANNEL_CREATE,
		function(data)
			local channel = self.channels:get(data.id)
			if not channel then return end
			self:emit(
				Client.events.CHANNEL_CREATE,
				channel
			)
		end
	)
	self.socket:on(
		Socket.events.CHANNEL_UPDATE,
		function(data)
			local channel = self.channels:get(data.id)
			if not channel then return end
			self:emit(
				Client.events.CHANNEL_UPDATE,
				channel
			)
		end
	)
	self.socket:on(
		Socket.events.CHANNEL_DELETE,
		function(data)
			self:emit(
				Client.events.CHANNEL_DELETE,
				data
			)
		end
	)
	--
	self.socket:on(
		Socket.events.MESSAGE_CREATE,
		function(data)
			local channel = self.channels:get(data.channel_id)
			if not channel then return end
			local message = channel.history:get(data.id)
			if not message then return end
			self:emit(
				Client.events.MESSAGE_CREATE,
				message
			)
		end
	)
	self.socket:on(
		Socket.events.MESSAGE_UPDATE,
		function(data)
			local channel = self.channels:get(data.channel_id)
			if not channel then return end
			local message = channel.history:get(data.id)
			if not message then return end
			self:emit(
				Client.events.MESSAGE_UPDATE,
				message
			)
		end
	)
	self.socket:on(
		Socket.events.MESSAGE_DELETE,
		function(data)
			local channel = self.channels:get(data.channel_id)
			if not channel then return end
			self:emit(
				Client.events.MESSAGE_DELETE,
				data
			)
		end
	)
	self.socket:on(
		Socket.events.MESSAGE_REACTION_ADD,
		function(data)
			local user = self.users:get(data.user_id)
			if not user then return end
			local channel = self.channels:get(data.channel_id)
			if not channel then return end
			local message = channel.history:get(data.message_id)
			if not message then return end
			local reaction = message.reactions:get(data.emoji.id)
			if not reaction then return end
			self:emit(
				Client.events.MESSAGE_REACTION_ADD,
				reaction,
				user
			)
		end
	)
	self.socket:on(
		Socket.events.MESSAGE_REACTION_REMOVE,
		function(data)
			local channel = self.channels:get(data.channel_id)
			if not channel then return end
			local message = channel.history:get(data.message_id)
			if not message then return end
			local user = self.users:get(data.user_id)
			local reaction = message.reactions:get(data.emoji.id)
			self:emit(
				Client.events.MESSAGE_REACTION_REMOVE,
				reaction or data,
				user or data.user_id
			)
		end
	)
	--
	self.socket:on(
		Socket.events.GUILD_CREATE,
		function(data)
			local server = self.servers:get(data.id)
			if not server then return end
			self:emit(
				Client.events.GUILD_CREATE,
				server
			)
		end
	)
	self.socket:on(
		Socket.events.GUILD_UPDATE,
		function(data)
			local server = self.servers:get(data.id)
			if not server then return end
			self:emit(
				Client.events.GUILD_UPDATE,
				server
			)
		end
	)
	self.socket:on(
		Socket.events.GUILD_DELETE,
		function(data)
			self:emit(
				Client.events.GUILD_DELETE,
				data
			)
		end
	)
	--
	self.socket:on(
		Socket.events.GUILD_ROLE_CREATE,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local role = server.roles:get(data.role.id)
			if not role then return end
			self:emit(
				Client.events.GUILD_ROLE_CREATE,
				role
			)
		end
	)
	self.socket:on(
		Socket.events.GUILD_ROLE_UPDATE,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local role = server.roles:get(data.role.id)
			if not role then return end
			self:emit(
				Client.events.GUILD_ROLE_UPDATE,
				role
			)
		end
	)
	self.socket:on(
		Socket.events.GUILD_ROLE_DELETE,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			self:emit(
				Client.events.GUILD_ROLE_DELETE,
				data
			)
		end
	)
	--
	self.socket:on(
		Socket.events.GUILD_MEMBER_ADD,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local member = server.members:get(data.user.id)
			if not member then return end
			self:emit(
				Client.events.GUILD_MEMBER_ADD,
				member
			)
		end
	)
	self.socket:on(
		Socket.events.GUILD_MEMBER_UPDATE,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local member = server.members:get(data.user.id)
			if not member then return end
			self:emit(
				Client.events.GUILD_MEMBER_UPDATE,
				member
			)
		end
	)
	self.socket:on(
		Socket.events.GUILD_MEMBER_REMOVE,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local user = self.users:get(data.user.id)
			self:emit(
				Client.events.GUILD_MEMBER_REMOVE,
				user or data
			)
		end
	)
	--
	self.socket:on(
		Socket.events.GUILD_BAN_ADD,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local ban = server.bans:get(data.id)
			if not ban then return end
			self:emit(
				Client.events.GUILD_BAN_ADD,
				ban
			)
		end
	)
	self.socket:on(
		Socket.events.GUILD_BAN_REMOVE,
		function(data)
			local server = self.servers:get(data.guild_id)
			if not server then return end
			local user = self.users:get(data.id)
			self:emit(
				Client.events.GUILD_BAN_REMOVE,
				user or data
			)
		end
	)
	--[[
		Returning an user
			GUILD_BAN_REMOVE
			GUILD_MEMBER_REMOVE
		Returning raw data
			CHANNEL_DELETE
			MESSAGE_DELETE
			GUILD_DELETE
			GUILD_ROLE_DELETE
		Returning raw data if no reaction
			MESSAGE_REACTION_REMOVE
	]]
	--
	self.__wrappedHandlers = nil
end

function Client:edit (config)
	return self.rest:request(
		Route(
			'users/@me'
		),
		config,
		'PATCH'
	)
end
function Client:setName (name)
	return self:edit({
		username = name,
	})
end
function Client:setAvatar (avatar)
	return self:edit({
		avatar = avatar,
	})
end

function Client:setStatus (config)
	self.user.game = config.game or self.user.game
	self.user.idle = config.idle or self.user.idle
	return self.socket:send(
		Socket.codes.STATUS_UPDATE,
		{
			game = self.user.game,
			idle_since = self.user.idle,
		}
	)
end
function Client:setIdle (idle)
	return self:setStatus({
		idle = idle,
	})
end
function Client:setGame (game)
	game = game or ''
	return self:setStatus({
		game = {
			name = game.name or game,		
		},
	})
end

function Client:acceptInvite (code)
	return self.rest:request(
		Route(
			'invites/%s',
			code
		),
		nil,
		'POST'
	)
end

function Client:getRegions ()
	return self.rest:request(
		Route(
			'voice/regions'
		)
	)
end
function Client:createGuild (name, region, icon)
	region = region.id or region
	local data, err = self.rest:request(
		Route(
			'guilds'
		),
		{
			name = name,
			icon = icon,
			region = region,
		},
		'POST'
	)
	if not data then
		return data, err
	end
	local server = structures.Server(self)
	server:update(data)
	self.servers:add(server)
	return server
end

return Client