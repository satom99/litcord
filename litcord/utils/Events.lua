local Events = class()

function Events:__constructor ()
	self.__handlers = {}
end

function Events:once (...)
	self:on(..., true)
end
function Events:on (events, callback, once)
	if type(events) ~= 'table' then
		events = {events}
	end
	for _,name in ipairs(events) do
		table.insert(
			self.__handlers,
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
	local offset = 0
	for i = 1, #self.__handlers do
		i = i - offset
		local handler = self.__handlers[i]
		if handler.name == name then
			if handler.once then
				table.remove(
					self.__handlers,
					i
				)
				offset = offset + 1
			end
			coroutine.wrap(
				handler.callback
			)(...)
		end
	end
end

return Events