local Events = class()

function Events:__constructor ()
	self._handlers = {}
end

function Events:once (a, b)
	self:on(a, b, true)
end
function Events:on (events, callback, once)
	if type(events) ~= 'table' then
		events = {events}
	end
	for _,name in ipairs(events) do
		table.insert(
			self._handlers,
			{
				once = once,
				name = tonumber(name) or name:lower(),
				callback = callback,
			}
		)
	end
end

function Events:emit (name, ...)
	name = tonumber(name) or name:lower()
	for i = 1, #self._handlers do
		local handler = self._handlers[i]
		if handler.name == name then
			if handler.once then
				table.remove(
					self._handlers,
					i
				)
				i = i - 1
			end
			handler.callback(...)
		end
	end
end

return Events