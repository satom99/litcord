local class = require('./new')
--
local EventsBased = class()

function EventsBased:__constructor ()
	self.__eventHandlers = {}
end
function EventsBased:once (events, callback)
	self:on(events, callback, true)
end
function EventsBased:on (events, callback, once)
	if type(events) == 'string' then
		events = {events}
	end
	for _,name in ipairs(events) do
		table.insert(
			self.__eventHandlers,
			{
				once = once,
				name = name:lower(),
				callback = callback,
			}
		)
	end
end
function EventsBased:dispatchEvent (name, data)
	local removed = 0
	for i,v in ipairs(self.__eventHandlers) do
		if v.name == name:lower() then
			v.callback(data)
			if v.once then
				table.remove(self.__eventHandlers, i)
				removed = removed + 1
			end
		end
	end
end

return EventsBased