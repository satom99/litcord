local Sock = class(utils.Events)
Sock.beat = 0
Sock.codes = {
	DISPATCH = 0,
	HEARTBEAT = 1,
	IDENTIFY = 2,
	STATUS_UPDATE = 3,
	VOICE_STATE_UPDATE = 4,
	VOICE_SERVER_PING = 5,
	RESUME = 6,
	RECONNECT = 7,
	REQUEST_GUILD_MEMBERS = 8,
	INVALID_SESSION = 9,
	HELLO = 10,
	HEARTBEAT_ACK = 11,
}
Sock.gateway = 'wss://gateway.discord.gg/?v=6'

function Sock:__constructor (linda, token, settings)
	self:__dependencies()
	self:__initHandlers()
	self.linda = linda
	self.token = token
	self.shard = settings.shard
	self.index = (self.shard and self.shard[1]) or 0
	self:connect()
	while true do
		self:process()
	end
end

function Sock:__dependencies ()
	json = require('lunajson')
	errno = require('cqueues.errno')
	clock = require('cqueues').monotime
	WebSocket = require('http.websocket')
	self.__dependencies = nil
end

function Sock:__initHandlers ()
	self:on(
		Sock.codes.DISPATCH,
		function(data, sequence, event)
			event = event:lower()
			self.sequence = sequence
			self.linda:send(
				'r',
				{
					event,
					data
				}
			)
			--
			if event == 'ready' then
				self.session = data.session_id
			end
		end
	)
	--
	self:on(
		Sock.codes.RECONNECT,
		function()
			print('* Requested reconnect.', self.index)
			self:reconnect()
		end	
	)
	self:on(
		Sock.codes.INVALID_SESSION,
		function()
			print('* Invalid session.', self.index)
			self.session = nil
			self:reconnect()
		end
	)
	self:on(
		Sock.codes.HELLO,
		function(data)
			self.interval = data.heartbeat_interval * 10^-3 * .75 
			if not (self.session and self.sequence) then
				self:send(
					Sock.codes.IDENTIFY,
					{
						token = self.token,
						properties = {
							['$os'] = '',
							['$device'] = 'litcord',
							['$browser'] = 'litcord',
							['$referrer'] = '',
							['$referring_domain'] = 'github.com/satom99/litcord',
						},
						compress = false,
						large_threshold = 250,
						shard = self.shard,
					}
				)
			else
				self:send(
					Sock.codes.RESUME,
					{
						token = self.token,
						session_id = self.session,
						seq = self.sequence,
					}
				)
			end
		end
	)
	self.__initHandlers = nil
end

function Sock:reconnect ()
	self.socket:close()
	self:connect()
end

function Sock:connect ()
	print('Connecting.', self.index)
	local socket = WebSocket.new_from_uri(self.gateway)
	local success, err = socket:connect(15)
	if not success then
		error(errno[err])
	end
	socket.socket:setmaxerrs(-1)
	socket.socket:settimeout(30)
	self.socket = socket
	print('Connected.', self.index)
end

function Sock:process ()
	-- Sending
	local _,data = self.linda:receive(0, 'w')
	if data then
		self:send(
			unpack(data)
		)
	end
	-- Receiving
	local data, frame = self.socket:receive()
	if not data then
		if frame == errno.ETIMEDOUT then
			print('* Timed out, reconnecting.', self.index)
			self:reconnect()
		elseif frame == 'Broken pipe' then
			print('* Broken pipe, reconnecting.', self.index)
			self:reconnect()
		else
			error(frame)
		end
	elseif frame == 'text' then
		data = json.decode(data)
		self:emit(
			data.op,
			data.d,
			data.s,
			data.t
		)
	else
		print('* Unhandled frame of type: '..frame, self.index)
	end
	-- Heartbeat
	if self.interval and self.sequence then
		if (clock() - self.beat) > 0 then
			self.beat = clock() + self.interval
			self:send(
				Sock.codes.HEARTBEAT,
				self.sequence
			)
		end
	end
end

function Sock:send (op, data)
	self.socket:send(
		json.encode(
			{
				op = op,
				d = data,
			}
		)
	)
end

return Sock