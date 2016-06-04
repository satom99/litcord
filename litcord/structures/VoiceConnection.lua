local json = require('json')
local timer = require('timer')
local dns = require('dns')
local dgram = require('dgram')
local Buffer = require('buffer').Buffer
local WebSocket = require('coro-websocket')

local constants = require('../constants')

local base = require('./base')
local class = require('../classes/new')

local VoiceConnection = class(base)

function VoiceConnection:__constructor () -- .parent = channel / .parent = server / .parent = client
	do
		print('* Voice is not fully implemented yet.')
		self.parent:leave()
		return
	end
	--
	self.status = constants.socket.status.IDLE
	self.parent.parent.parent:once(
		{
			constants.events.VOICE_STATE_UPDATE,
			constants.events.VOICE_SERVER_UPDATE,
		},
		function(data)
			self:update(data)
		end
	)
	self.parent.parent.parent.socket:send(
		constants.socket.OPcodes.VOICE_STATE_UPDATE,
		{
			channel_id = self.parent.id,
			guild_id = self.parent.parent.id,
			self_mute = false,
			self_deaf = false,
		}
	)
end

function VoiceConnection:disconnect ()
	self.__write()
end

function VoiceConnection:__onUpdate ()
	if (self.status == constants.socket.status.CONNECTED) or not self.user_id or not self.session_id or not self.token or not self.guild_id or not self.endpoint then return end
	local parsed = WebSocket.parseUrl('wss://'..self.endpoint..'/')
	self.endpoint = parsed.host -- removing port from endpoint, basically
	coroutine.wrap(
		function()
			self:__connect()
		end
	)()
end

function writeUIntBE (buffer, value, offset, length)
	value = math.abs(value)
	value = bit.tobit(value)
	offset = bit.rshift(offset, 31)
	length = bit.rshift(length, 31)
	local i = length - 1
	local mul = 1
	buffer[offset + i] = bit.band(value, 0xFF)
	print('b')
	while (i >= 0) do
		buffer[offset + i] = bit.band(bit.rshift((value / mul), 31), 0xFF)
		i = i - 1
		mul = mul * 0x100
	end
end

function VoiceConnection:__events (opcode, data)
	if opcode == constants.voice.OPcodes.READY then
		self.timer = timer.setInterval(
			data.heartbeat_interval,
			function()
				self:__send(
					constants.voice.OPcodes.HEARTBEAT
				)
			end
		)
		--
		self:__initUDP(data)
	end
end

function VoiceConnection:__initUDP (data)
	local packet = Buffer:new(70)
	packet[1] = data.ssrc
	--writeUIntBE(packet, data.ssrc, 0, 4)
	--
	self.__udp = dgram.createSocket(
		'udp4',
		function(data)
			print('udp data: '..tostring(data))
		end
	)
	for port = 0, 65535 do
		self.__udp:bind(
			port,
			'0.0.0.0',
			{
				exclusive = true,
			}
		)
	end
	print('resolving: '..self.endpoint)
	dns.resolve4(
		self.endpoint,
		function(_, addresses)
			local address = addresses[1].address
			print('UDP: '..address..':'..data.port)
			self.__udp:send(
				packet:toString(0, 4),
				data.port,
				address,
				function(err)
					if err then
						print('udp send error: '..tostring(err))
						os.exit()
					end
				end
			)
		end
	)
end

function VoiceConnection:__send (opcode, data)
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

function VoiceConnection:__connect ()
	local endpoint = 'wss://'..self.endpoint..'/'
	local url = WebSocket.parseUrl(endpoint)
	url.port = 443
	_, self.__read, self.__write = WebSocket.connect(url)
	self.status = constants.socket.status.CONNECTED
	--
	print('Connected to voice ws.')
	self:__send(
		constants.voice.OPcodes.IDENTIFY,
		{
			user_id = self.user_id,
			session_id = self.session_id,
			token = self.token,
			server_id = self.guild_id,
		}
	)
	--
	self:__listen()
end

function VoiceConnection:__listen () -- reading
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
						self:__events(data.op, data.d)
					else -- disconnected
						self.timer:stop()
						self.timer:close()
						self.timer = nil
					end
				end
			end
		end
	)()
end

return VoiceConnection