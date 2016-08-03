return
{
	status = {
		IDLE = 3,
		CONNECTED = 0,
		CONNECTING = 1,
		RECONNECTING = 2,
	},
	events = {
		READY = 'ready',
		-- Users
		USER_UPDATE = 'user_update',
		PRESENCE_UPDATE = 'presence_update',
		-- Channels
		CHANNEL_CREATE = 'channel_create',
		CHANNEL_UPDATE = 'channel_update',
		CHANNEL_DELETE = 'channel_delete',
		-- Messages
		MESSAGE_CREATE = 'message_create',
		MESSAGE_UPDATE = 'message_update',
		MESSAGE_DELETE = 'message_delete',
		MESSAGE_DELETE_BULK = 'message_delete_bulk',
		-- Guilds
		GUILD_CREATE = 'guild_create',
		GUILD_UPDATE = 'guild_update',
		GUILD_DELETE = 'guild_delete',
		GUILD_ROLE_CREATE = 'guild_role_create',
		GUILD_ROLE_UPDATE = 'guild_role_update',
		GUILD_ROLE_DELETE = 'guild_role_delete',
		GUILD_MEMBER_ADD = 'guild_member_add',
		GUILD_MEMBER_UPDATE = 'guild_member_update',
		GUILD_MEMBERS_CHUNK = 'guild_members_chunk',
		GUILD_MEMBER_REMOVE = 'guild_member_remove',
		GUILD_BAN_ADD = 'guild_ban_add',
		GUILD_BAN_REMOVE = 'guild_ban_remove',
	},
	OPcodes = {
		DISPATCH = 0,
		HEARTBEAT = 1,
		IDENTIFY = 2,
		STATUS_UPDATE = 3,
		VOICE_STATE_UPDATE = 4,
		VOICE_SERVER_PING = 5,
		RESUME = 6,
		RECONNECT = 7,
		REQUEST_GUILD_MEMBERS = 8,
		INVALID_SESSION = 9,
		HELLO = 10,
		HEARTBEAT_ACK = 11,	
	},
}