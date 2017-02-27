local Routiner = class()

function Routiner:add (routine)
	table.insert(self, routine)
end

function Routiner:process ()
	for i = 1, #self do
		local routine = self[i]
		local status = coroutine.status(routine)
		if status == 'dead' then
			table.remove(self, i)
			i = i - 1
		else
			local resumed, err = coroutine.resume(routine)
			if not resumed then
				error(err)
			end
		end
	end
end

return Routiner