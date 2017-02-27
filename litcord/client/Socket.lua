local lanes = require('lanes').configure()
local Sock = lanes.require('litcord.client.Sock')

local Socket = class(utils.Events)
Socket.codes = Sock.codes
Socket.events = {
	READY = 'ready',
	--
	USER_UPDATE = 'user_update',
	PRESENCE_UPDATE = 'presence_update',
	--
	CHANNEL_CREATE = 'channel_create',
	CHANNEL_UPDATE = 'channel_update',
	CHANNEL_DELETE = 'channel_delete',
	--
	MESSAGE_CREATE = 'message_create',
	MESSAGE_UPDATE = 'message_update',
	MESSAGE_DELETE = 'message_delete',
	MESSAGE_DELETE_BULK = 'message_delete_bulk',
	MESSAGE_REACTION_ADD = 'message_reaction_add',
	MESSAGE_REACTION_REMOVE = 'message_reaction_remove',
	--
	GUILD_CREATE = 'guild_create',
	GUILD_UPDATE = 'guild_update',
	GUILD_DELETE = 'guild_delete',
	--
	GUILD_ROLE_CREATE = 'guild_role_create',
	GUILD_ROLE_UPDATE = 'guild_role_update',
	GUILD_ROLE_DELETE = 'guild_role_delete',
	--
	PRESENCE_UPDATE = 'presence_update',
	GUILD_MEMBER_ADD = 'guild_member_add',
	GUILD_MEMBERS_CHUNK = 'guild_members_chunk',
	GUILD_MEMBER_UPDATE = 'guild_member_update',
	GUILD_MEMBER_REMOVE = 'guild_member_update',
	--
	GUILD_BAN_ADD = 'guild_ban_add',
	GUILD_BAN_REMOVE = 'guild_ban_remove',
}
Socket.thread = lanes.gen(
	'*',
	function(linda, token, settings)
		set_error_reporting('extended')
		set_finalizer(
			function(err, stk)
				print(err)
			end
		)
		--
		sock = Sock(linda, token, settings)
	end
)

function Socket:__constructor (parent)
	self.parent = parent
	self.linda = lanes.linda()
end

function Socket:run ()
	self.thread = Socket.thread(
		self.linda,
		self.parent.token,
		self.parent.settings
	)
end

function Socket:process ()
	local count = self.linda:count('r') or 0
	local handlers = {
		self.linda:receive(
			0,
			self.linda.batched,
			'r',
			count
		)
	}
	table.remove(handlers, 1)
	for _,handler in ipairs(handlers) do
		self:emit(
			unpack(handler)
		)
	end
	coroutine.yield()
end

function Socket:send (op, data)
	self.linda:send(
		'w',
		{
			op,
			data
		}
	)
end

return Socket