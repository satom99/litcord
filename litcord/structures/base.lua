local class = require('../classes/new')

local base = class()

function base:__constructor (parent)
	self.parent = parent
end

function base:update (data)
	for k,v in pairs(data) do
		self[k] = v
	end
	self:__onUpdate()
end

function base:__onUpdate ()
end

return base