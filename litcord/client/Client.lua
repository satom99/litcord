local rest = require('litcord.client.rest')
local Socket = require('litcord.client.Socket')

local Client = class(utils.Events)

function Client:__constructor (settings)
	self.settings = utils.merge(
		constants.settings,
		settings
	)
	self.users = utils.Cache()
	self.servers = utils.Cache()
	self.channels = utils.Cache()
	--
	self.rest = rest(self)
	self.socket = Socket(self)
	self:__initHandlers()
end

function Client:__initHandlers ()
	-- Ready
	self.socket:on(
		constants.socket.events.READY,
		function(data)
			self.user = structures.User(self)
			self.user:update(data.user)
			self.users:add(self.user)
			for _,guild in ipairs(data.guilds) do
				self.socket:emit(
					constants.socket.events.GUILD_CREATE,
					guild
				)
			end
			for _,channel in ipairs(data.private_channels) do
				self.socket:emit(
					constants.socket.events.CHANNEL_CREATE,
					channel
				)
			end
		end
	)
	-- Users
	self.socket:on(
		constants.socket.events.USER_UPDATE,
		function(data)
			local user = self.users:get('id', data.id)
			if not user then
				user = structures.User(self)
				self.users:add(user)
			end
			user:update(data)
		end
	)
	-- Channels
	self.socket:on(
		{
			constants.socket.events.CHANNEL_CREATE,
			constants.socket.events.CHANNEL_UPDATE,
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
				local channel = recipient.channel
				if not channel then
					channel = structures.Channel(recipient)
					self.channels:add(channel)
					recipient.channel = channel
				end
				channel:update(data)
			else
				local server = self.servers:get('id', data.guild_id)
				if not server then return end
				local overwrites = data.permission_overwrites or {}
				data.permission_overwrites = nil
				data.guild_id = nil
				local channel = server.channels:get('id', data.id)
				if not channel then
					channel = structures.Channel(server)
					self.channels:add(channel)
					server.channels:add(channel)
				end
				channel:update(data)
				channel.overwrites = utils.Cache()
				for _,v in ipairs(overwrites) do
					local overwrite = structures.Overwrite(channel)
					overwrite:update(v)
					channel.overwrites:add(overwrite)
				end
			end
		end
	)
	self.socket:on(
		constants.socket.events.CHANNEL_DELETE,
		function(data)
			if data.is_private then
				local recipient = self.users:get('id', data.recipient.id)
				if not recipient or not recipient.channel then return end
				self.channels:remove(recipient.channel)
				recipient.channel = nil
			else
				local server = self.servers:get('id', data.guild_id)
				if not server then return end
				local channel = server.channels:get('id', data.id)
				if not channel then return end
				self.channels:remove(channel)
				server.channels:remove(channel)
			end
		end
	)
	-- Messages
	self.socket:on(
		constants.socket.events.MESSAGE_CREATE,
		function(data)
			local channel = self.channels:get('id', data.channel_id)
			if not channel then return end
			local message = channel.history:get('id', data.id)
			if not message then
				if data.author then
					local author = self.users:get('id', data.author.id)
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
		constants.socket.events.MESSAGE_UPDATE,
		function(data)
			local channel = self.channels:get('id', data.channel_id)
			if not channel then return end
			local message = channel.history:get('id', data.id)
			if not message then return end
			message:update(data)
		end
	)
	self.socket:on(
		constants.socket.events.MESSAGE_DELETE,
		function(data)
			local channel = self.channels:get('id', data.channel_id)
			if not channel then return end
			local message = channel.history:get('id', data.id)
			if not message then return end
			channel.history:remove(message)
		end
	)
	self.socket:on(
		constants.socket.events.MESSAGE_DELETE_BULK,
		function(data)
			for _,id in ipairs(data.ids) do
				self.socket:emit(
					constants.socket.events.MESSAGE_DELETE,
					{
						id = id,
						channel_id = data.channel_id,
					}
				)
			end
		end
	)
	-- Servers
	self.socket:on(
		{
			constants.socket.events.GUILD_CREATE,
			constants.socket.events.GUILD_UPDATE,
		},
		function(data)
			local roles = data.roles or {}
			local members = data.members or {}
			local channels = data.channels or {}
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
			for _,role in ipairs(roles) do
				self.socket:emit(
					constants.socket.events.GUILD_ROLE_CREATE,
					{
						role = role,
						guild_id = data.id,
					}
				)
			end
			for _,member in ipairs(members) do
				member.guild_id = data.id
				self.socket:emit(
					constants.socket.events.GUILD_MEMBER_ADD,
					member
				)
			end
			for _,channel in ipairs(channels) do
				channel.guild_id = data.id
				self.socket:emit(
					constants.socket.events.CHANNEL_CREATE,
					channel
				)
			end
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_DELETE,
		function(data)
			local server = self.servers:get('id', data.id)
			if not server then return end
			for _,member in ipairs(server.members.__data) do
				self.socket:emit(
					constants.socket.events.GUILD_MEMBER_REMOVE,
					{
						user = member.user,
						guild_id = data.id,
					}
				)
			end
			self.servers:remove(server)
		end
	)
	self.socket:on(
		{
			constants.socket.events.GUILD_ROLE_CREATE,
			constants.socket.events.GUILD_ROLE_UPDATE,
		},
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			local role = server.roles:get('id', data.role.id)
			if not role then
				role = structures.Role(server)
				server.roles:add(role)
			end
			role:update(data.role)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_ROLE_DELETE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			server.roles:remove(data.role_id)
		end
	)
	self.socket:on(
		{
			constants.socket.events.PRESENCE_UPDATE,
			constants.socket.events.GUILD_MEMBER_ADD,
			constants.socket.events.GUILD_MEMBER_UPDATE,
		},
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			local user = self.users:get('id', data.user.id)
			if not user then
				user = structures.User(self)
				self.users:add(user)
			end
			user:update(data.user)
			user.servers:add(server)
			--
			local member = server.members:get('id', user.id)
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
		constants.socket.events.GUILD_MEMBERS_CHUNK,
		function(data)
			for _,member in ipairs(data.members) do
				member.guild_id = data.guild_id
				self.socket:emit(
					constants.socket.events.GUILD_MEMBER_ADD,
					member
				)
			end
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_MEMBER_REMOVE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			local user = self.users:get('id', data.user.id)
			if not user then return end
			user.servers:remove(server)
			server.members:remove(user)
			if #user.servers.__data < 1 then
				self.users:remove(user)
			end
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_BAN_ADD,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server or not server.bans then return end
			local user = self.users:get('id', data.id)
			if not user then
				user = structures.User(self)
				self.users:add(user)
			end
			user:update(data)
			server.bans:add(user)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_BAN_REMOVE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server or not server.bans then return end
			local ban = server.bans:get('id', data.id)
			if not ban then return end
			server.bans:remove(ban)
		end
	)
	---------------------
	--[[ Custom events ]]
	self.socket:on(
		constants.socket.events.READY,
		function()
			self:emit(
				constants.events.ready
			)
		end
	)
	-- Users
	self.socket:on(
		constants.socket.events.USER_UPDATE,
		function(data)
			self:emit(
				constants.events.userUpdate,
				self.users:get('id', data.id)
			)
		end
	)
	-- Channels
	self.socket:on(
		constants.socket.events.CHANNEL_CREATE,
		function(data)
			self:emit(
				constants.events.channelCreate,
				self.channels:get('id', data.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.CHANNEL_UPDATE,
		function(data)
			self:emit(
				constants.events.channelUpdate,
				self.channels:get('id', data.id)
			)
		end
	)
	-- Messages
	self.socket:on(
		constants.socket.events.MESSAGE_CREATE,
		function(data)
			local channel = self.channels:get('id', data.channel_id)
			if not channel then return end
			self:emit(
				constants.events.messageCreate,
				channel.history:get('id', data.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.MESSAGE_UPDATE,
		function(data)
			local channel = self.channels:get('id', data.channel_id)
			if not channel then return end
			self:emit(
				constants.events.messageUpdate,
				channel.history:get('id', data.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.MESSAGE_DELETE,
		function(data)
			local channel = self.channels:get('id', data.channel_id)
			if not channel then return end
			self:emit(
				constants.events.messageDelete,
				channel.history:get('id', data.id)
			)
		end
	)
	-- Servers
	self.socket:on(
		constants.socket.events.GUILD_CREATE,
		function(data)
			self:emit(
				constants.events.serverCreate,
				self.servers:get('id', data.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_UPDATE,
		function(data)
			self:emit(
				constants.events.serverUpdate,
				self.servers:get('id', data.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_DELETE,
		function(data)
			self:emit(
				constants.events.serverDelete,
				self.servers:get('id', data.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_ROLE_CREATE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			self:emit(
				constants.events.roleCreate,
				server.roles:get('id', data.role.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_ROLE_UPDATE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			self:emit(
				constants.events.roleUpdate,
				server.roles:get('id', data.role.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_ROLE_DELETE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			self:emit(
				constants.events.roleDelete,
				server.roles:get('id', data.role_id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.PRESENCE_UPDATE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			self:emit(
				constants.events.presenceUpdate,
				server.members:get('id', data.user.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_MEMBER_ADD,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			self:emit(
				constants.events.memberJoin,
				server.members:get('id', data.user.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_MEMBER_UPDATE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			self:emit(
				constants.events.memberUpdate,
				server.members:get('id', data.user.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_MEMBER_REMOVE,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			self:emit(
				constants.events.memberLeave,
				server.members:get('id', data.user.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_BAN_ADD,
		function(data)
			local server = self.servers:get('id', data.guild_id)
			if not server then return end
			self:emit(
				constants.events.memberBan,
				server.members:get('id', data.user.id)
			)
		end
	)
	self.socket:on(
		constants.socket.events.GUILD_BAN_REMOVE,
		function(data)
			self:emit(
				constants.events.memberUnban,
				self.users:get('id', data.id)
			)
		end
	)
	---------------------
	self.__initHandlers = nil
end

function Client:login (tmail, password)
	if not tmail then return end
	self.socket.token = tmail
	if password then
		local response = self.rest:request(
			{
				method = 'POST',
				path = 'auth/login',
				data = {
					email = tmail,
					password = password,
				},
			}
		)
		if not response then
			error('Wrong login details.')
			return
		end
		self.socket.token = response.token
	end
	if not self.socket.token:lower():find('mfa.') then
		self.socket.token = 'Bot '..self.socket.token
	end
	self.socket:connect()
end

function Client:setSettings (config)
	self.rest:request(
		{
			method = 'PATCH',
			path = 'users/@me',
			data = {
				avatar = config.avatar or self.user.avatar,
				username = config.username or self.user.username,
			},
		}
	)
end
function Client:setName (name)
	self:setSettings({
		username = name,
	})
end
function Client:setAvatar (avatar)
	self:setSettings({
		avatar = avatar,
	})
end

function Client:setStatus (config)
	if config.idle == nil then
		config.idle = self.user.idle and (self.user.idle > 0)
	end
	self.user.idle = (config.idle and 1) or 0
	if type(config.game) == 'table' then
		self.user.game = utils.merge(
			self.user.game,
			config.game
		)
	else
		self.user.game = (
			config.game and {
				name = config.game,
			}
		) or self.user.game or {}
	end
	self.socket:send(
		constants.socket.OPcodes.STATUS_UPDATE,
		{
			game = self.user.game,
			idle_since = self.user.idle,
		}
	)
end
function Client:setIdle (idle)
	self:setStatus({
		idle = idle,
	})
end
function Client:setGame (game)
	self:setStatus({
		game = game,
	})
end

function Client:acceptInvite (code)
	self.rest:request(
		{
			method = 'POST',
			path = 'invites/'..code,
		}
	)
end

function Client:getRegions ()
	return self.rest:request(
		{
			method = 'GET',
			path = 'voice/regions',
		}
	)
end
function Client:createGuild (name, region, icon)
	region = tonumber(region) or region.id
	local data = self.rest:request(
		{
			method = 'POST',
			path = 'guilds',
			data = {
				name = name,
				icon = icon,
				region = region,
			},
		}
	)
	if not data then return end
	local server = structures.Server(self)
	self.servers:add(server)
	server:update(data)
	return server
end

return Client