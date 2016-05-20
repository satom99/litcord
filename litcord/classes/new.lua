return function(parent)
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
				if parent.__constructor then
					parent.__constructor(object, ...)
				end
				if methods.__constructor then
					methods.__constructor(object, ...)
				end
				object.__constructor = nil
				return object
			end,
		}
	)
	return class
end