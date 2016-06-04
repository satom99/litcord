local classes = require('../classes')
local base = require('./base')

local User = classes.new(base)

function User:__constructor ()
	self.servers = classes.Cache()
end

return User