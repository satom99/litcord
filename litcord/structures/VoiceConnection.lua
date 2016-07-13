local json = require('json')
local WebSocket = require('coro-websocket')

local constants = require('../constants')

local base = require('./base')
local class = require('../classes/new')
local voice = require('../voice')

local VoiceConnection = class(base)

function VoiceConnection:__constructor () -- .parent = server / .parent = client
	do
		print('* Voice is not fully implemented yet.')
		--return
	end
	--
	self.__data = {}
	self.__udp = voice.UDP(self)
	self.__socket = voice.Socket(self)
	self.__socket:on(
		constants.voice.OPcodes.READY,
		function(data)
			self.__udp:connect(data)
		end
	)
	--
	self.parent.parent:once(
		{
			constants.events.VOICE_STATE_UPDATE,
			constants.events.VOICE_SERVER_UPDATE,
		},
		function(data)
			for k,v in pairs(data) do
				self.__data[k] = v
			end
			self:__onUpdate()
		end
	)
end

function VoiceConnection:connect (channelID)
	if self.__socket.status == constants.socket.status.CONNECTED then
		self:disconnect()
	end
	--
	self.parent.parent.socket:send(
		constants.socket.OPcodes.VOICE_STATE_UPDATE,
		{
			channel_id = channelID,
			guild_id = self.parent.id,
			self_mute = false,
			self_deaf = false,
		}
	)
end

function VoiceConnection:setSpeaking (state)
	self.__socket:send(
		constants.voice.OPcodes.SPEAKING,
		{
			speaking = state,
		}
	)
end

function VoiceConnection:disconnect ()
	self.__manualDisconnect = true
	self.__socket:disconnect()
	self:__disconnect()
end

function VoiceConnection:__disconnect ()
	self.__data = {}
	self.__udp:disconnect()
	self.parent.parent.socket:send(
		constants.socket.OPcodes.VOICE_STATE_UPDATE,
		{
			channel_id = json.null,
			guild_id = self.parent.id,
			self_mute = false,
			self_deaf = false,
		}
	)
end

function VoiceConnection:__onUpdate ()
	if (self.__socket.status == constants.socket.status.CONNECTED) or not self.__data.user_id or not self.__data.session_id or not self.__data.token or not self.__data.guild_id or not self.__data.endpoint then return end
	local parsed = WebSocket.parseUrl('wss://'..self.__data.endpoint..'/')
	self.__data.endpoint = parsed.host -- removing port from endpoint, basically
	coroutine.wrap(
		function()
			self.__socket:connect()
		end
	)()
end

return VoiceConnection