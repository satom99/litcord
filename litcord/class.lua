local function recursive (object, class, ...)
	local methods_meta = getmetatable(class)
	if not methods_meta then return end
	local methods = methods_meta.__index
	local parent = getmetatable(methods).__index
	recursive(object, parent, ...)
	if methods.__constructor ~= parent.__constructor then
		methods.__constructor(object, ...)
	end
end

return function (parent)
	parent = parent or {}
	local methods = setmetatable(
		{},
		{
			__index = parent,
		}
	)
	local class = setmetatable(
		{},
		{
			__index = methods,
			__newindex = methods,
			__call = function(self, ...)
				local object = setmetatable(
					{},
					{
						__index = methods,
					}
				)
				recursive(object, self, ...)
				object.__constructor = nil
				return object
			end,
		}
	)
	return class
end