local function hasbit(x, p)
	return x % (p + p) >= p       
end
local function setbit(x, p)
	return hasbit(x, p) and x or x + p
end
local function clearbit(x, p)
	return hasbit(x, p) and x - p or x
end

local Bitwise = class()

function Bitwise:__constructor (parent, value)
	self.parent = parent
	self.value = value or 0
end

function Bitwise:has (value)
	value = tonumber(value) or constants.permissions[value]
	return hasbit(self.value, value)
end

function Bitwise:add (value)
	value = tonumber(value) or constants.permissions[value]
	self.value = setbit(self.value, value)
	self.parent:__updatedBitwise()
end

function Bitwise:remove (value)
	value = tonumber(value) or constants.permissions[value]
	self.value = clearbit(self.value, value)
	self.parent:__updatedBitwise()
end

return Bitwise