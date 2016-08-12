local ltn12  = require('ltn12')
local https = require('ssl.https')

local rest = class(constants.rest)

function rest:__constructor (parent)
	self.parent = parent
end

function rest:request (request)
	while self.limited do
		utils.sleep(250)
	end
	--
	local response = {}
	request.url = self.base..'/'..request.path
	request.path = nil
	request.sink = ltn12.sink.table(response)
	request.headers = {
		['User-Agent'] = library.name..' ('..library.homepage..', '..library.version..')',
		['Authorization'] = self.parent.socket.token,
	}
	if request.data then
		request.data = json.encode(request.data)
		request.source = ltn12.source.string(request.data)
		request.headers['Content-Type'] = 'application/json'
		request.headers['Content-Length'] = #request.data
	end
	local _, code, headers = https.request(request)
	if code > 399 then
		if code == 429 then
			local retry = 0
			for k,v in pairs(headers) do
				if k:lower() == 'retry-after' then
					retry = v
					break
				end
			end
			self.limited = true
			utils.sleep(retry)
			self.limited = false
			return self:request(request)
		elseif code == 502 then
			utils.sleep(250)
			return self:request(request)
		end
		print('* Unhandled REST error '..code)
		return
	end
	response = table.concat(response)
	return json.decode(response)
end

return rest