json = require('lunajson')
class = require('litcord.class')
utils = require('litcord.utils')
constants = require('litcord.constants')
structures = {}
structures.base = require('litcord.structures.base')
structures = require('litcord.structures')
library = {
	name = 'litcord',
	version = 'indev',
	homepage = 'http://github.com/satom99/litcord',
}

return require('litcord.client')