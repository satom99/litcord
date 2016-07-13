local json = require('json')
local timer = require('timer')
local WebSocket = require('coro-websocket')

local constants = require('../constants')

local classes = require('../classes')

local Socket = classes.new(classes.EventsBased)

function Socket:__constructor (parent)
	self.parent = parent
	self.status = constants.socket.status.IDLE
	self:__initHandlers()
end

function Socket:__initHandlers ()
	self:on(
		constants.voice.OPcodes.READY,
		function(data)
			self.timer = timer.setInterval(
			data.heartbeat_interval,
				function()
					self:send(
						constants.voice.OPcodes.HEARTBEAT
					)
				end
			)
		end
	)
	self.__initHandlers = nil
end

function Socket:disconnect ()
	self.__write()
end

function Socket:connect ()
	local endpoint = 'wss://'..self.parent.__data.endpoint..'/'
	local url = WebSocket.parseUrl(endpoint)
	url.port = 443
	_, self.__read, self.__write = WebSocket.connect(url)
	self.status = constants.socket.status.CONNECTED
	--
	print('Connected to voice ws.')
	self:send(
		constants.voice.OPcodes.IDENTIFY,
		{
			user_id = self.parent.__data.user_id,
			session_id = self.parent.__data.session_id,
			token = self.parent.__data.token,
			server_id = self.parent.__data.guild_id,
		}
	)
	--
	self:__listen()
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

function Socket:__listen ()
	coroutine.wrap(
		function()
			while true do
				if not self.__read then break end
				if type(self.__read) == 'string' then -- most likely an error
					print(self.__read)
					return
				else
					local read = self.__read()
					if read and read.payload then
						local data = json.decode(read.payload)
						self:dispatchEvent(data.op, data.d)
					else
						self.status = constants.socket.status.IDLE
						print('Disconnected from voice ws.')
						if self.timer then
							self.timer:stop()
							self.timer:close()
							self.timer = nil
						end
						if not self.parent.__manualDisconnect then
							self.parent:__disconnect()
						end
						self.parent.__manualDisconnect = false
					end
				end
			end
		end
	)()
end

return Socket