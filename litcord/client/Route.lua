local Route = class()

function Route:__constructor (base, ...)
	self.base = base
	self.full = base:format(...)
end

return Route