local base = class()

function base:__constructor (parent)
	self.parent = parent
end

function base:__updated () end

function base:update (data)
	for k,v in pairs(data) do
		self[k] = v
	end
	self:__updated()
end

return base