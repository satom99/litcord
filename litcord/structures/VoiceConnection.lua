local json = require('json')
local timer = require('timer')
local WebSocket = require('coro-websocket')

local constants = require('../constants')

local base = require('./base')
local class = require('../classes/new')

local VoiceConnection = class(base)

function VoiceConnection:__constructor () -- .parent = channel / .parent = server / .parent = client
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
	self.timer:stop()
end

function VoiceConnection:__onUpdate ()
	if not self.user_id or not self.session_id or not self.token or not self.guild_id or not self.endpoint then return end
	self.endpoint = 'wss://'..self.endpoint..'/'
	coroutine.wrap(
		function()
			self:__connect()
		end
	)()
end

function VoiceConnection:__events (opcode, data)
	if opcode == 2 then
		self:update(data)
		--
		self.timer = timer.setInterval(
			data.heartbeat_interval,
			function()
				self:send(3)
			end
		)
	end
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
	local url = WebSocket.parseUrl(self.endpoint)
	_, self.__read, self.__write = WebSocket.connect(url)
	--
	self:__send(
		0,
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
				if type(self.__read) == 'string' then
					print(self.__read)
				end
				local read = self.__read()
				if read and read.payload then
					local data = json.decode(read.payload)
					self:__events(data.op, data.d)
				else
					-- disconnected
				end
			end
		end
	)()
end

return VoiceConnection