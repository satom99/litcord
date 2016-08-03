return function(interval)
	local final = os.time() + interval
	while os.time() > final do end
end