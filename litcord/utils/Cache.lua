local Cache = class()

function Cache:__constructor (discriminator)
	self.__data = {}
	self.discriminator = discriminator or 'id'
end

function Cache:getAll (key, value)
	local objects = {}
	for _,v in ipairs(self.__data) do
		if v[key] == value then
			table.insert(objects, v)
		end
	end
	return objects
end

function Cache:get (key, value)
	return self:getAll(key, value)[1]
end

function Cache:remove (okey, value)
	if type(okey) == 'table' then
		value = okey[self.discriminator]
		okey = self.discriminator
	end
	for i,v in ipairs(self.__data) do
		if v[okey] == value then
			table.remove(self.__data, i)
			break
		end
	end
end

function Cache:add (object)
	local existent = self:get(
		self.discriminator,
		object[self.discriminator]
	)
	if not existent then
		table.insert(self.__data, object)
	end
end

return Cache