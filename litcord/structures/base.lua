local Base = class()

function Base:__constructor (parent)
	self.parent = parent
end

function Base:__updated() end

function Base:update (data)
	for k,v in pairs(data) do
		self[k] = v
	end
	self:__updated()
end

return Base