local function put (where, key, value)
	local existant = where[key]
	if (type(existant) == 'table') and (type(value) == 'table') then
		for k,v in pairs(value) do
			put(existant, k, v)
		end
	else
		where[key] = value
	end
end

return function(base, new)
	new = new or {}
	base = base or {}
	local result = {}
	for k,v in pairs(base) do
		result[k] = v
	end
	for k,v in pairs(new) do
		put(result, k, v)
	end
	return result
end