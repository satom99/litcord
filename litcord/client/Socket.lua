local json = require('json')
local timer = require('timer')
local WebSocket = require('coro-websocket')

local class = require('../classes/new')
local package = require('../package')
local constants = require('../constants')


local Socket = class()

function Socket:__constructor (client)
	self.client = client
	self.status = constants.socket.status.IDLE
	--
	client:on(
		constants.events.READY,
		function(data)
			self.timer = timer.setInterval(
				data.heartbeat_interval,
				function()
					self:send(
						constants.socket.OPcodes.HEARTBEAT,
						self.sequence
					)
				end
			)
		end
	)
end

function Socket:send (opcode, data)
	if not self.__write then return end
	coroutine.wrap(
		function()
			self.__write(
				{
					opcode = 1,
					payload = json.encode(
						{
							op = opcode,
							d = data,
						}
					),
				}
			)
		end
	)()
end

function Socket:connect ()
	if self.status == constants.socket.status.CONNECTED then return end
	if not self.gateway then
		print('Retrieving gateway.')
		self.gateway = self.client.rest:request(
			{
				method = 'GET',
				path = 'gateway',
			}
		).url..'/'
	end
	print('Connecting.')
	local url = WebSocket.parseUrl(self.gateway)
	_, self.__read, self.__write = WebSocket.connect(url)
	--
	if not self.__read or not self.__write then
		print('Unable to connect.')
		return
	end
	--
	self.status = constants.socket.status.CONNECTED
	print('Connected, identifying.')
	self:send(
		constants.socket.OPcodes.IDENTIFY,
		{
			token = self.token,
			properties =
			{
				['$os'] = package.name,
				['$device'] = package.name,
				['$browser'] = '',
				['$referrer'] = '',
				['$referring_domain'] = package.homepage,
			},
			compress = false,
			large_threshold = self.client.settings.large_threshold,
		}
	)
	--
	self:__listen()
end

function Socket:__reconnect ()
	self:connect()
end

function Socket:__listen () -- reading
	print('Listening.')
	coroutine.wrap(
		function()
			while true do
				if not self.__read then break end
				local read = self.__read()
				if read and read.payload then
					local data = json.decode(read.payload)
					if data.op == constants.socket.OPcodes.DISPATCH then
						self.sequence = data.s
						self.client:dispatchEvent(data.t, data.d)
					end
				else
					print('Disconnected.')
					self.status = constants.socket.status.IDLE
					if self.client.settings.auto_reconnect then
						print('Reconnecting.')
						self.status = constants.socket.status.RECONNECTING
						self:__reconnect()
					end
					timer.clearInterval(self.timer)
					break
				end
			end
		end
	)()
end

return Socket