json = require('lunajson')
class = require('litcord.class')
utils = require('litcord.utils')
constants = require('litcord.constants')
structures = {}
structures.base = require('litcord.structures.base')
structures = require('litcord.structures')

package.path = package.path..';?.5.rockspec;'
require('litcord.litcord-0')
library = {
	name = package,
	version = version,
	homepage = description.homepage,
}

return require('litcord.client')