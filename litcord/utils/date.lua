local months = {
	Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
	Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12,
}
local pattern = '%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+) GMT'

return function(remote) -- http://stackoverflow.com/a/4600967
	local offset = os.time() - os.time(os.date('!*t'))
	local day, month, year, hour, min, sec = remote:match(pattern)
	remote = os.time(
		{
			year = year,
			month = months[month],
			day = day,
			hour = hour,
			min = min,
			sec = sec,
		}
	)
	return remote + offset
end