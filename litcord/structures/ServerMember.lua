local classes = require('../classes')
local base = require('./base')

local ServerMember = classes.new(base)

function ServerMember:__onUpdate () -- parent = server / server.parent = client |=> .parent.parent equals to client
	self.id = self.user.id
	self.user = self.parent.parent.users:get('id', self.user.id)
	for _,v in ipairs(self.roles) do
		local role = self.parent.roles:get('id', v)
		v = role
	end
end

function ServerMember:edit (config)
	self.parent.parent.rest:request(
		{
			method = 'PATCH',
			path = 'guilds/'..self.parent.id..'/members/'..self.user.id,
			data = config,
		}
	)
end
function ServerMember:setNickname (name)
	self:edit({nick = name})
end
function ServerMember:setMuted (bool)
	self:edit({mute = bool})
end
function ServerMember:setDeaf (bool)
	self:edit({deaf = bool})
end
function ServerMember:move (channel)
	local id = channel
	if type(channel) == 'table' then
		id = channel.id
	end
	self:edit({channel_id = id})
end
function ServerMember:addRole (role)
	local id = role
	if type(role) == 'table' then
		id = role.id
	end
	--
	local roles = {}
	for _,v in ipairs(self.roles) do
		if v.id == id then
			return -- avoiding unnecessary requests
		end
		table.insert(roles, v.id)
	end
	table.insert(roles, id)
	--
	self:edit({roles = roles})
end
function ServerMember:revokeRole (role)
	local id = role
	if type(role) == 'table' then
		id = role.id
	end
	--
	local found
	local roles = {}
	for _,v in ipairs(self.roles) do
		if v.id == id then
			found = true
			table.remove(roles, v.id)
		else
			table.insert(roles, v.id)
		end
	end
	--
	if not found then return end -- avoiding unnecessary requests
	self:edit({roles = roles})
end

function ServerMember:kick ()
	self.parent.parent.rest:request(
		{
			method = 'DELETE',
			path = 'guilds/'..self.parent.id..'/members/'..self.user.id,
		}
	)
end

function ServerMember:ban (days)
	self.parent.parent.rest:request(
		{
			method = 'PUT',
			path = 'guilds/'..self.parent.id..'/bans/'..self.user.id,
			data = {
				['delete-message-days'] = days or 0,
			},
		}
	)
end

return ServerMember