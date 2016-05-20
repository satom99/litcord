local json = require('json')

local classes = require('../classes')
local constants = require('../constants')
local structures = require('../structures')

local rest = require('./rest')
local Socket = require('./Socket')


local Client = classes.new(classes.EventsBased)

function Client:__constructor (settings)
	-- Settings
	self.settings = constants.settings
	if settings then
		for k,v in pairs(settings) do
			self.settings[k] = v
		end
	end
	-- Storage
	self.users = classes.Cache()
	self.servers = classes.Cache()
	self.__channels = classes.Cache()
	-- Core
	self.rest = rest(self)
	self.socket = Socket(self)
	--
	self:__initHandlers()
end

function Client:login (config)
	if not config or (not config.token and not (config.email and config.password)) then return end
	coroutine.wrap(
		function()
			self.socket.token = config.token or self.rest:request(
				{
					method = 'POST',
					path = self.rest.endPoints.LOGIN,
					data =
					{
						email = config.email,
						password = config.password,
					},
				}
			).token
			self.socket:connect()
		end
	)()
end

-- Stats
function Client:setStats (config)
	if config.game then
		self.socket:send(
			constants.socket.OPcodes.STATUS_UPDATE,
			{
				idle_since = json.null,
				game = {
					name = config.game,
				}
			}
		)
	end
	if config.name or config.avatar then
		self.rest:request(
			{
				method = 'PATCH',
				path = self.rest.endPoints.USERS_ME,
				data = config,
			}
		)
	end
end
function Client:setGame (game)
	self:setStats({game = game})
end
function Client:setName (name)
	self:setStats({name = name})
end
function Client:setAvatar (avatar)
	self:setStats({avatar = avatar})
end

-- Invites
function Client:acceptInvite (code)
	self.rest:request(
		{
			method = 'POST',
			path = 'invites/'..code,
		}
	)
end

-- Creating guilds
function Client:getRegions ()
	return self.rest:request(
		{
			method = 'GET',
			path = self.rest.endPoints.VOICE_REGIONS,
		}
	)
end
function Client:createServer (name, region, icon)
	local guild = self.rest:request(
		{
			method = 'POST',
			path = self.rest.endPoints.GUILDS,
			data = {
				name = name,
				region = region,
				icon = icon,
			},
		}
	)
	local server = structures.Server(self)
	self.servers:add(server)
	server:update(guild)
	return server
end

function Client:__initHandlers ()
	-- Ready
	self:on(
		constants.events.READY,
		function(data)
			local user = structures.User(self)
			user:update(data.user)
			self.users:add(user)
			self.user = user
			for _,v in ipairs(data.private_channels) do
				self:dispatchEvent(constants.events.CHANNEL_CREATE, v)
			end
		end
	)
	-- Users
	self:on(
		constants.events.PRESENCE_UPDATE,
		function(data)
			local user = self.users:get('id', data.id)
			if data.status == 'offline' then
				if user then
					self.users:remove(user)
				end
				return
			end
			if not user then
				user = structures.User(self)
				self.users:add(user)
			end
			user:update(data)
		end
	)
	-- Channels
	self:on(
		{
			constants.events.CHANNEL_CREATE,
			constants.events.CHANNEL_UPDATE,
		},
		function(data)
			if data.is_private then
				local recipient = self.users:get('id', data.recipient.id)
				if not recipient then
					recipient = structures.User(self)
					self.users:add(recipient)
				end
				recipient:update(data.recipient)
				--
				data.recipient = nil
				if not recipient.channel then
					recipient.channel = structures.Channel(recipient) -- so that 'client' is accessible through User's parent
					self.__channels:add(recipient.channel)
				end
				recipient.channel:update(data)
			else
				local server = self.servers:get('id', data.guild_id)
				if not server then return end -- should exist
				--
				data.guild_id = nil
				local channel = server.channels:get('id', data.id)
				if not channel then
					channel = structures.Channel(server)
					server.channels:add(channel)
					self.__channels:add(channel)
				end
				channel:update(data)
			end
		end
	)
	self:on(
		constants.events.CHANNEL_DELETE,
		function(data)
			if data.is_private then
				local recipient = self.users:get('id', data.recipient.id)
				if not recipient then return end
				recipient.channel = nil
				self.__channels:remove(recipient.channel)
			else
				local server = self.servers:get('id', data.guild_id)
				if not server then return end -- should exist
				local channel = server.channels:get('id', data.id)
				if not channel then return end
				server.channels:remove(channel)
				self.__channels:remove(channel)
			end
		end
	)
	-- Messages
	self:on(
		constants.events.MESSAGE_CREATE,
		function(data)
			local channel = self.__channels:get('id', data.channel_id)
			if not channel then return end -- rip
			--
			local author = self.users:get('id', data.author.id)
			if not author then
				author = structures.User(self)
				self.users:add(author)
			end
			author:update(data.author)
			--
			local message = structures.Message(channel, author)
			channel.history:add(message)
			message:update(data)
			self:dispatchEvent(
				'message',
				message
			)
		end
	)
	self:on(
		constants.events.MESSAGE_UPDATE,
		function(data)
			local channel = self.__channels:get('id', data.channel_id)
			if not channel then return end -- rip
			local message = channel.history:get('id', data.id)
			if not message then return end
			message:update(data)
			self:dispatchEvent(
				'messageUpdated',
				message
			)
		end
	)
	-- Guilds
	self:on(
		{
			constants.events.GUILD_CREATE,
			constants.events.GUILD_UPDATE,
		},
		function(data)
			local roles = data.roles
			local members = data.members
			local channels = data.channels
			data.roles = nil
			data.members = nil
			data.channels = nil
			--
			local server = self.servers:get('id', data.id)
			if not server then
				server = structures.Server(self)
				self.servers:add(server)
			end
			server:update(data)
			--
			for _,v in ipairs(members) do
				self:dispatchEvent(constants.events.GUILD_MEMBER_ADD, v)
			end
			--
			for _,v in ipairs(channels) do
				v.guild_id = data.id
				self:dispatchEvent(constants.events.CHANNEL_CREATE, v)
			end
			--
			for _,v in ipairs(roles) do
				self:dispatchEvent(
					constants.events.GUILD_ROLE_CREATE,
					{
						guild_id = data.id,
						role = v,
					}
				)
			end
		end
	)
	self:on(
		constants.events.GUILD_DELETE,
		function(data)
			self.servers:remove(data)
		end
	)
	-- Guild members
	self:on(
		constants.events.GUILD_MEMBER_ADD,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			local user = self.users:get('id', data.user.id)
			if not user then
				user = structures.User(self)
				self.users:add(user)
			end
			user:update(data.user)
			--
			local member = structures.ServerMember(server)
			member:update(data)
			server.members:add(member)
		end
	)
	self:on(
		constants.events.GUILD_MEMBER_REMOVE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			server.members:remove(data.user)
		end
	)
	-- Guild roles
	self:on(
		{
			constants.events.GUILD_ROLE_CREATE,
			constants.events.GUILD_ROLE_UPDATE,
		},
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			local role = server.roles:get('id', data.role.id)
			if not role then
				role = structures.Role(self)
				server.roles:add(role)
			end
			role:update(data.role)
			server.roles:add(role)
		end
	)
	self:on(
		constants.events.GUILD_ROLE_DELETE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			server.roles:remove(data.role)
		end
	)
	-- Guild bans
	self:on(
		constants.events.GUILD_BAN_ADD,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			local user = self.users:get('id', data.id)
			if not user then
				user = structures.User(self)
				self.users:add(user)
			end
			user:update(data)
			server.bans:add(user)
		end
	)
	self:on(
		constants.events.GUILD_BAN_REMOVE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			local ban = server.bans:get('id', user.id)
			if not ban then return end
			server.bans:remove(ban)
		end
	)
	--
	self.__initHandlers = nil
end

return Client