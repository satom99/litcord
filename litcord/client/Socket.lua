local json = require('json')
local timer = require('timer')
local WebSocket = require('coro-websocket')

local classes = require('../classes')
local package = require('../package')
local constants = require('../constants')


local Socket = classes.new(classes.EventsBased)

function Socket:__constructor (client)
	self.__client = client
	self.status = constants.socket.status.IDLE
	self:__initHandlers()
end

function Socket:__initHandlers ()
	self:on(
		constants.socket.OPcodes.DISPATCH,
		function(data)
			self.__sequence = data.s
			self.__client:dispatchEvent(data.t, data.d)
		end
	)
	--
	self:on(
		constants.socket.OPcodes.RECONNECT,
		function()
			self.__gateway = nil
			self.__write()
		end
	)
	self:on(
		constants.socket.OPcodes.INVALID_SESSION,
		function()
			self.__sessionID = nil
			self.__write()
		end
	)
	self:on(
		constants.socket.OPcodes.READY,
		function(data)
			data = data.d
			self.__sessionID = data.session_id
		end
	)
	self:on(
		constants.socket.OPcodes.HELLO,
		function(data)
			data = data.d
			self.__timer = timer.setInterval(
				data.heartbeat_interval,
				function()
					self:send(
						constants.socket.OPcodes.HEARTBEAT,
						self.__sequence
					)
				end
			)
			if not (self.__sessionID and self.__sequence) then
				print('Identifying.')
				self:send(
					constants.socket.OPcodes.IDENTIFY,
					{
						token = self.token,
						properties =
						{
							['$os'] = '',
							['$device'] = package.name,
							['$browser'] = package.name,
							['$referrer'] = '',
							['$referring_domain'] = package.homepage,
						},
						compress = false,
						large_threshold = self.__client.settings.large_threshold,
						shard = self.__client.settings.shard,
					}
				)
			else
				print('Resuming.')
				self:send(
					constants.socket.OPcodes.RESUME,
					{
						token = self.token,
						session_id = self.__sessionID,
						seq = self.__sequence,
					}
				)
			end
		end
	)
	self.__initHandlers = nil
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
	if not self.__gateway then
		print('Retrieving gateway.')
		local response = self.__client.rest:request(
			{
				method = 'GET',
				path = 'gateway',
			}
		)
		if not response then
			print('Unable to retrieve gateway.')
			return
		end
		self.__gateway = response.url..'/'
	end
	--
	print('Connecting.')
	local url = WebSocket.parseUrl(self.__gateway)
	url.pathname = url.pathname..'?v=5'
	_, self.__read, self.__write = WebSocket.connect(url)
	--
	if not self.__read or not self.__write then
		print('Unable to connect.')
		return
	end
	--
	self.status = constants.socket.status.CONNECTED
	self:__listen()
end

function Socket:__reconnect ()
	self:connect()
end

function Socket:__listen ()
	print('Listening.')
	coroutine.wrap(
		function()
			while true do
				if not self.__read then break end
				local read = self.__read()
				if read and read.payload then
					local data = json.decode(read.payload)
					self:dispatchEvent(data.op, data)
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