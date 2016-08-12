json = require('lunajson')
class = require('litcord.class')
utils = require('litcord.utils')
constants = require('litcord.constants')
structures = {}
structures.base = require('litcord.structures.base')
structures = require('litcord.structures')

require('litcord.package')
library = {
	name = package,
	version = version,
	homepage = description.homepage,
}

return require('litcord.client')