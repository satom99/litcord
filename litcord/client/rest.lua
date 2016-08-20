local ltn12  = require('ltn12')
local https = require('ssl.https')

local rest = class(constants.rest)

function rest:__constructor (parent)
	self.parent = parent
	self.limits = {}
end

function rest:request (config)
	local request = {}
	local response = {}
	request.url = self.base..'/'..config.path
	request.sink = ltn12.sink.table(response)
	request.method = config.method
	request.headers = {
		['User-Agent'] = library.name..' ('..library.homepage..', '..library.version..')',
		['Authorization'] = self.parent.socket.token,
	}
	if config.data then
		request.data = json.encode(config.data)
		request.source = ltn12.source.string(request.data)
		request.headers['Content-Type'] = 'application/json'
		request.headers['Content-Length'] = #request.data
	end
	--
	if self.limits.global then
		utils.sleep(self.limits.global)
		self.limits.global = nil
	elseif self.limits[request.method] then
		utils.sleep(self.limits[request.method])
		self.limits[request.method] = nil
	end
	--
	local _, code, headers = https.request(request)
	--
	local date = headers['date'] -- time
	local reset = headers['x-ratelimit-reset']
	local global = headers['x-ratelimit-global']
	local remaining = headers['x-ratelimit-remaining']
	if tostring(remaining) == '0' then
		self.limits[request.method] = reset - os.time()
	elseif global then
		self.limits.global = reset - os.time()
	end
	--
	if code > 399 then
		if code == 429 then
			return self:request(config)
		elseif code == 502 then
			utils.sleep(.25)
			return self:request(config)
		end
		print('* Unhandled REST error '..code)
		return
	end
	--
	response = table.concat(response)
	return (code == 204) or json.decode(response)
end

return rest