package = 'litcord'
version = 'scm-1'
source = {
	url = 'git://github.com/satom99/litcord',
	tag = 'indev',
}
description = {
	license = 'MIT',
	summary = 'An unofficial standalone Lua wrapper for Discord.',
	homepage = 'http://github.com/satom99/litcord',
	maintainer = 'AdamJames <satom99@github>',
}
dependencies = {
	'lua >= 5.1',
	'luasec',
	'lunajson',
	'lua-websockets',
}
build = {
	type = 'none',
	install = {
		lua = {
			['litcord.init'] = 'litcord/init.lua',
			['litcord.class'] = 'litcord/class.lua',
			--
			['litcord.utils.init'] = 'litcord/utils/init.lua',
			['litcord.utils.sleep'] = 'litcord/utils/sleep.lua',
			['litcord.utils.merge'] = 'litcord/utils/merge.lua',
			['litcord.utils.getTime'] = 'litcord/utils/getTime.lua',
			['litcord.utils.Timer'] = 'litcord/utils/Timer.lua',
			['litcord.utils.Cache'] = 'litcord/utils/Cache.lua',
			['litcord.utils.Events'] = 'litcord/utils/Events.lua',
			['litcord.utils.Bitwise'] = 'litcord/utils/Bitwise.lua',
			--
			['litcord.constants.init'] = 'litcord/constants/init.lua',
			['litcord.constants.rest'] = 'litcord/constants/rest.lua',
			['litcord.constants.socket'] = 'litcord/constants/socket.lua',
			['litcord.constants.events'] = 'litcord/constants/events.lua',
			['litcord.constants.permissions'] = 'litcord/constants/permissions.lua',
			--
			['litcord.structures.init'] = 'litcord/structures/init.lua',
			['litcord.structures.base'] = 'litcord/structures/base.lua',
			['litcord.structures.User'] = 'litcord/structures/User.lua',
			['litcord.structures.Channel'] = 'litcord/structures/Channel.lua',
			['litcord.structures.Message'] = 'litcord/structures/Message.lua',
			['litcord.structures.Server'] = 'litcord/structures/Server.lua',
			['litcord.structures.Invite'] = 'litcord/structures/Invite.lua',
			['litcord.structures.Role'] = 'litcord/structures/Role.lua',
			['litcord.structures.Member'] = 'litcord/structures/Member.lua',
			['litcord.structures.Overwrite'] = 'litcord/structures/Overwrite.lua',
			--
			['litcord.client.init'] = 'litcord/client/init.lua',
			['litcord.client.rest'] = 'litcord/client/rest.lua',
			['litcord.client.Socket'] = 'litcord/client/Socket.lua',
			['litcord.client.Client'] = 'litcord/client/Client.lua',
		},
	},
}