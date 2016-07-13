local dns = require('dns')
local dgram = require('dgram')
local Buffer = require('buffer').Buffer

local class = require('../classes/new')

local UDP = class()

local function writeUIntBE (buffer, value, offset, length)
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

function UDP:__constructor (parent)
	self.parent = parent
end

function UDP:disconnect ()
	if self.connection then
		self.connection:close()
		self.connection = nil
	end
end

function UDP:connect (data)
	self.connection = dgram.createSocket(
		'udp4',
		function(data)
			print('udp data: '..tostring(data))
		end
	)
	self.connection:bind(
		0,
		'0.0.0.0'
	)
	dns.resolve4(
		self.parent.__data.endpoint,
		function(_, addresses)
			local address = addresses[1].address
			print('UDP: '..address..':'..data.port)
			--
			local packet = Buffer:new(70)
			packet[1] = data.ssrc
			--writeUIntBE(packet, data.ssrc, 0, 4)
			--
			self.connection:send(
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
	self.parent:setSpeaking(true)
end

return UDP