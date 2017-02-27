local Events = class()

function Events:__constructor ()
	self._handlers = {}
end

function Events:on (events, callback, once)
	if type(events) ~= 'table' then
		events = {events}
	end
	for _,event in ipairs(events) do
		local handler = self._handlers[event]
		if not handler then
			self._handlers[event] = {}
		end
		table.insert(
			self._handlers[event],
			callback
		)
	end
end

function Events:emit (name, ...)
	local handler = self._handlers[name]
	if not handler then
		return
	end
	for _,back in ipairs(handler) do
		back(...)
	end
end


return Events