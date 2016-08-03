package = 'litcord'
version = 'indev'
source = {
	url = 'git://github.com/satom99/litcord',
	tag = version,
}
description = {
	license = 'MIT',
	summary = 'Yet another unofficial Lua client API for Discord.',
	homepage = 'http://github.com/satom99/litcord',
	maintainer = 'AdamJames <satom99@github>',
}
dependencies = {
	'lua >= 5.1',
	'LuaSec',
	'lunajson',
	'lua-websockets',
}
build = {
	type = 'none',
	install = {
		lua = {
			init = 'litcord/init',
			class = 'litcord/class',
		}
	},
	copy_directories = {
		'litcord/utils',
		'litcord/client',
		'litcord/constants',
		'litcord/structures',
	},
}