local json = require('json')
local timer = require('timer')
local WebSocket = require('coro-websocket')

local class = require('../classes/new')
local package = require('../package')
local constants = require('../constants')


local Socket = class()

function Socket:__constructor (client)
	self.__client = client
	self.status = constants.socket.status.IDLE
	--
	client:on(
		constants.events.READY,
		function(data)
			self.__sessionID = data.session_id
			self.__timer = timer.setInterval(
				data.heartbeat_interval,
				function()
					self:send(
						constants.socket.OPcodes.HEARTBEAT,
						self.__sequence
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

function Socket:disconnect()
	self.__manualDisconnect = true
	self.__write()
end

function Socket:connect ()
	if self.status == constants.socket.status.CONNECTED then return end
	if not self.gateway then
		print('Retrieving gateway.')
		self.gateway = self.__client.rest:request(
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
	if not (self.__sessionID and self.__sequence) then
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
				large_threshold = self.__client.settings.large_threshold,
			}
		)
	else
		print('Connected, resuming.')
		self:send(
			constants.socket.OPcodes.RESUME,
			{
				token = self.token,
				session_id = self.__sessionID,
				seq = self.__sequence,
			}
		)
	end
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
						self.__sequence = data.s
						self.__client:dispatchEvent(data.t, data.d)
					end
				else
					print('Disconnected.')
					if self.__timer then
						self.__timer:stop()
						self.__timer:close()
						self.__timer = nil
					end
					self.status = constants.socket.status.IDLE
					if not self.__manualDisconnect and self.__client.settings.auto_reconnect then
						print('Reconnecting.')
						self.status = constants.socket.status.RECONNECTING
						self:__reconnect()
					end
					self.__manualDisconnect = false
					break
				end
			end
		end
	)()
end

return Socket