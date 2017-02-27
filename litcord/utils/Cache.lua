local Cache = class()

function Cache:__constructor (discriminator)
	self.discriminator = discriminator or 'id'
	--
	local metatable = getmetatable(self)
	metatable.__call = self.iterator
	setmetatable(
		self,
		metatable
	)
end

function Cache:iterator ()
	local k, v
	return function()
		k, v = next(self, k)
		return tonumber(k) and v
	end
end

function Cache:getAll (key, value)
	if type(value) == 'nil' then
		value = key
		key = self.discriminator
	end
	local objects = {}
	for _,v in ipairs(self) do
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
	for i,v in ipairs(self) do
		if v[okey] == value then
			table.remove(self, i)
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
		table.insert(self, object)
	end
end

return Cache