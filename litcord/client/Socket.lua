local WebSocket = require('websocket').client.sync

local Socket = class(utils.Events)

function Socket:__constructor (parent)
	self.parent = parent
	self.status = constants.socket.status.IDLE
	self:__initHandlers()
end

function Socket:__initHandlers ()
	self:on(
		constants.socket.OPcodes.DISPATCH,
		function(data, sequence, event)
			event = event:lower()
			self.sequence = sequence
			self:emit(
				event,
				data
			)
		end
	)
	self:on(
		constants.socket.events.READY,
		function(data)
			self.session_id = data.session_id
		end
	)
	--
	self:on(
		constants.socket.OPcodes.RECONNECT,
		function()
			self.gateway = nil
			self:disconnect()
			self:connect()
		end	
	)
	self:on(
		constants.socket.OPcodes.INVALID_SESSION,
		function()
			self.session_id = nil
			self:disconnect()
			self:connect()
		end
	)
	--
	self:on(
		constants.socket.OPcodes.HELLO,
		function(data)
			self.heartbeat = utils.Timer(
				function()
					self:send(
						constants.socket.OPcodes.HEARTBEAT,
						self.sequence
					)
				end,
				data.heartbeat_interval / 2
			)
			if not (self.session_id and self.sequence) then
				print('Identifying.')
				self:send(
					constants.socket.OPcodes.IDENTIFY,
					{
						token = self.token,
						compress = false,
						properties = {
							['$os'] = '',
							['$device'] = library.name,
							['$browser'] = library.name,
							['$referrer'] = '',
							['$referring_domain'] = library.homepage,
						},
						large_threshold = 250,
						shard = self.parent.settings.shard,
					}
				)
			else
				print('Resuming.')
				self:send(
					constants.socket.OPcodes.RESUME,
					{
						token = self.token,
						session_id = self.session_id,
						seq = self.sequence,
					}
				)
			end
		end
	)
	self.__initHandlers = nil
end

function Socket:disconnect()
	self.disconnect_manual = true
	self.socket:close()
end

function Socket:connect ()
	if self.status == constants.socket.status.CONNECTED then return end
	if not self.gateway then
		local response = self.parent.rest:request(
			{
				path = 'gateway',
			}
		)
		if not response then
			error('Unable to retrieve gateway.')
			return
		end
		self.gateway = response.url..'/?v=5'
	end
	--
	print('Connecting.')
	self.socket = WebSocket()
	local _, failed = self.socket:connect(
		self.gateway,
		nil,
		{
			mode = 'client',
			protocol = 'any',
		}
	)
	if failed then
		error('Unable to connect. ('..failed..')')
		return
	end
	--
	self.status = constants.socket.status.CONNECTED
	self:listen()
end

function Socket:send (op, data)
	if self.status == constants.socket.status.CONNECTED then
		self.socket:send(
			json.encode(
				{
					op = op,
					d = data,
				}
			),
			1
		)
	end
end

function Socket:listen ()
	coroutine.wrap(
		function()
			while true do
				local payload, _, _, code, reason = self.socket:receive()
				if not payload then
					print('* Socket closed with code '..code..' ('..reason..')')
					self.status = constants.socket.status.IDLE
					self.heartbeat:stop()
					if not self.disconnect_manual then
						self:connect() -- reconnect
					end
					self.disconnect_manual = false
					break
				else
					payload = json.decode(payload)
					self:emit(
						payload.op,
						payload.d,
						payload.s,
						payload.t
					)
					self.heartbeat:loop()
				end
			end
		end	
	)()
end

return Socket