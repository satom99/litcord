local Timer = class()

function Timer:__constructor (func, interval, times)
	self.func = func
	self.times = times
	self.interval = interval
	self:restart()
end

function Timer:stop ()
	self.status = false
end

function Timer:restart ()
	self.last = utils.getTime()
	self.current = 0
	self.status = true
end

function Timer:loop ()
	if not self.status then return end
	local current = utils.getTime()
	if (self.last + self.interval) < current then
		self.last = current
		self.func()
		if self.times then
			self.current = self.current + 1
			if self.current == self.times then
				self:stop()
			end
		end
	end
end

return Timer