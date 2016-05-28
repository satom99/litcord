local json = require('json')
local http = require('coro-http')
local timer = require('timer')

local base = require('../constants/rest')
local class = require('../classes/new')
local package = require('../package')

local function Error (code, message)
	print('* Unhandled REST error: '..code..' - '..message)
end

local rest = class(base)

function rest:__constructor (client)
	self.client = client
end

function rest:request (config)
	if not config or not config.path then return end
	while self.rateLimited do
		timer.sleep(500)
	end
	--
	local data = (config.data or {})
	local method = (config.type or config.method or 'GET'):upper()
	local headers =
	{
		{
			'User-Agent',
			package.name..' ('..package.homepage..', '..package.version..')'
		},
		{
			'Authorization',
			self.client.socket.token
		},
	}
	if method == 'GET' then
		config.path = config.path..'?z'
		for k,v in pairs(data) do
			config.path = config.path..'&'..k..'='..v
		end
		data = nil
	elseif method == 'DELETE' then
		data = nil
		-- nothing
	else
		table.insert(
			headers,
			{
				'Content-Type',
				'application/json',
			}
		)
		data = json.encode(data)
	end
	local response, received = http.request(
		method,
		rest.base..'/'..config.path,
		headers,
		data
	)
	if response.code > 399 then
		if response.code == 429 then
			local retry = 0
			for _,v in ipairs(response) do
				if v[1] == 'Retry-After' then
					retry = v[2]
				end
			end
			self.rateLimited = true
			timer.sleep(retry)
			self.rateLimited = false
			return self:request(config)
		elseif response.code == 502 then
			timer.sleep(250)
			return self:request(config)
		end
		return Error(response.code, response.reason..' ('..config.path..')')
	end
	return json.decode(received)
end

return rest