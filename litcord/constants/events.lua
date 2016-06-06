return
{
	-- Status
	READY = 'ready',
	
	-- Messages
	MESSAGE_UPDATE = 'message_update',
	MESSAGE_CREATE = 'message_create',
	MESSAGE_DELETE = 'message_delete',
	MESSAGE_DELETE_BULK = 'message_delete_bulk',
	
	-- Users
	USER_UPDATE = 'user_update',
	PRESENCE_UPDATE = 'presence_update',
	
	-- Guilds
	GUILD_CREATE = 'guild_create',
	GUILD_UPDATE = 'guild_update',
	GUILD_DELETE = 'guild_delete',
	GUILD_MEMBER_ADD = 'guild_member_add',
	GUILD_MEMBER_UPDATE = 'guild_member_update',
	GUILD_MEMBERS_CHUNK = 'guild_members_chunk',
	GUILD_MEMBER_REMOVE = 'guild_member_remove',
	GUILD_ROLE_CREATE = 'guild_role_create',
	GUILD_ROLE_UPDATE = 'guild_role_update',
	GUILD_ROLE_DELETE = 'guild_role_delete',
	GUILD_BAN_ADD = 'guild_ban_add',
	GUILD_BAN_REMOVE = 'guild_ban_remove',
	
	-- Channels
	CHANNEL_CREATE = 'channel_create',
	CHANNEL_UPDATE = 'channel_update',
	CHANNEL_DELETE = 'channel_delete',
	
	-- Voice
	VOICE_STATE_UPDATE = 'voice_state_update',
	VOICE_SERVER_UPDATE = 'voice_server_update',
}