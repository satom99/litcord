local json = require('lunajson')
local clock = require('cqueues').monotime
local request = require('http.request')

local Rest = class()
Rest.base = 'https://discordapp.com/api/v6/'
Rest.limits = {}

function Rest:__constructor (parent)
	self.parent = parent
	self.headers = {
		['content-type'] = 'application/json',
		['authorization'] = 'Bot '..parent.token,
		['user-agent'] = ('%s %s (%s)'):format('litcord', '1.0.0', 'github.com/satom99/litcord'),
	}
end

function Rest:request (route, content, method)
	local limit = self.limits[route.base] or 0
	while limit > clock() do
		coroutine.yield()
	end
	--
	method = method or 'GET'
	if (method == 'GET') and content then
		local query = '?'
		for k,v in pairs(content) do
			query = query.. k..'='..v..'&'
		end
		route.full = route.full .. query
		content = nil
	end
	local request = request.new_from_uri(self.base .. route.full)
	for key,value in pairs(self.headers) do
		request.headers:upsert(key, value)
	end
	request.headers:upsert(':method', method)
	if content then
		request:set_body(
			json.encode(content)
		)
	end
	local headers, stream = request:go(5)
	if not headers then
		return false, stream
	end
	local body, err = stream:get_body_as_string()
	if not body then
		return false, err
	end
	--
	local status = headers:get(':status')
	status = tonumber(status)
	local remaining = headers:get('x-ratelimit-remaining')
	remaining = tonumber(remaining or '1')
	if status > 399 then
		if status == 502 then
			coroutine.yield() -- delay instead (?)
			return self:request(route, content, method)
		elseif status == 429 then -- should never happen
			local retry = headers:get('retry-after')
			retry = tonumber(retry) * 10^-3
			self.limits[route.base] = clock() + retry
			return self:request(route, content, method)
		end
		return false, status
	elseif remaining == 0 then -- avoiding status 429
		local remote = headers:get('date')
		local reset = headers:get('x-ratelimit-reset')
		local correct = utils.date(remote)
		local offset = reset - correct
		self.limits[route.base] = clock() + offset
	end
	--
	local method = request.headers:get(':method')
	if (method ~= 'GET') and (method ~= 'POST') then
		status = 204
	end
	return (status == 204) or json.decode(body)
end

return Rest