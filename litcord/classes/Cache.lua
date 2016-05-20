local class = require('./new')

local Cache = class()

function Cache:__constructor (discriminator)
	self.discriminator = discriminator or 'id'
	self.__data = {}
end

function Cache:get (key, value)
	for _,v in ipairs(self.__data) do
		if v[key] == value then
			return v
		end
	end
end

function Cache:getAll (key, value, all)
	local cache = {}
	for _,v in ipairs(self.__data) do
		if v[key] == value then
			table.insert(cache, v)
		end
	end
	return cache
end

function Cache:remove (object)
	for i,v in ipairs(self.__data) do
		if v[self.discriminator] == object[self.discriminator] then
			table.remove(self.__data, i)
			v = nil
			break
		end
	end
end

function Cache:add (object)
	local existent = self:get(self.discriminator, object[self.discriminator])
	if not existent then
		table.insert(self.__data, object)
	end
end

function Cache:update (new)
	for _,v in ipairs(self.__data) do
		if v[self.discriminator] == new[self.discriminator] then
			v = new
			break
		end
	end
end

return Cache