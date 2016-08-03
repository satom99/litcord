local getTime = require('socket').gettime

return function()
	return getTime() * 1000
end