local bit = require('bit') -- bitop

local function hasbit(x, p)
	return x % (p + p) >= p       
end
local function setbit(x, p)
	return hasbit(x, p) and x or x + p
end
local function clearbit(x, p)
	return hasbit(x, p) and x - p or x
end

local class = require('../classes/new')
local base = require('./base')

local constants = require('../constants')

local Permissions = class(base) -- .parent = Overwrite/Role / .parent = server / .parent = client

function Permissions:__update (value)
	value = value or 0
	self.allow = value
	self.deny = bit.bnot(value)
end

function Permissions:add (name)
	local value = constants.permissions[name:upper()]
	self.allow = setbit(self.allow, value)
	self.deny = bit.bnot(self.allow)
	if self.parent.__updatedPermissions then
		self.parent:__updatedPermissions()
	end
end

function Permissions:remove (name)
	local value = constants.permissions[name:upper()]
	self.allow = clearbit(self.allow, value)
	self.deny = bit.bnot(self.allow)
	if self.parent.__updatedPermissions then
		self.parent:__updatedPermissions()
	end
end

function Permissions:has (name)
	local value = constants.permissions[name:upper()]
	return hasbit(self.allow, value)
end

return Permissions