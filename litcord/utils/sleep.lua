return function(interval)
	local final = os.time() + interval
	repeat until os.time() > final
end