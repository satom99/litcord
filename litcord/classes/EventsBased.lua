local class = require('./new')
--
local EventsBased = class()

function EventsBased:__constructor ()
	self.__eventHandlers = {}
end
function EventsBased:once (name, callback)
	self.on(name, callback, true)
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
	for _,v in ipairs(self.__eventHandlers) do
		if v.name == name:lower() then
			v.callback(data)
		end
	end
end

return EventsBased