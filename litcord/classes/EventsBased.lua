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
	if type(events) ~= 'table' then
		events = {events}
	end
	for _,name in ipairs(events) do
		table.insert(
			self.__eventHandlers,
			{
				once = once,
				name = tonumber(name) or name:lower(),
				callback = callback,
			}
		)
	end
end
function EventsBased:dispatchEvent (name, data)
	name = tonumber(name) or name:lower()
	local removed = 0
	for i = 1, #self.__eventHandlers do
		i = i - removed
		local v = self.__eventHandlers[i]
		if v.name == name then
			coroutine.wrap(
				function()
					v.callback(data)
				end
			)()
			if v.once then
				table.remove(self.__eventHandlers, i)
				removed = removed + 1
			end
		end
	end
end

return EventsBased