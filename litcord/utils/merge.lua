return function(base, new)
	return setmetatable(
		new or {},
		{
			__index = base,
		}
	)
end