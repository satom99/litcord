return
{
	license = 'MIT',
	version = '0.0.6',
	name = 'satom99/litcord',
	description = 'Yet another unofficial Lua client API for Discord.',
	author = "Santi 'AdamJames' T. <satom99@github>",
	homepage = 'https://github.com/satom99/litcord',
	tags =
	{
		'lua',
		'luvit',
		'discord',
		'api',
	},
	files = {
		'*.lua',
		'client/*.lua',
		'classes/*.lua',
		'constants/*.lua',
		'structures/*.lua',
	},
	dependencies = {
		'luvit/json@2.5.2',
		'luvit/timer@2.0.0',
		'luvit/secure-socket@1.1.3',
		'creationix/coro-http@2.1.1',
		'creationix/coro-websocket@1.0.0-1',
	},
}