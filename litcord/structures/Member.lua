local base = require('litcord.structures.base')

local Member = class(base)

function Member:__updated ()
	for i,role in ipairs(self.roles) do
		self.roles[i] = self.parent.roles:get(role)
	end
end

function Member:kick ()
	return self.parent.parent.rest:request(
		Route(
			'guilds/%s/members/%s',
			self.parent.id,
			self.id
		),
		nil,
		'DELETE'	
	)
end

function Member:ban (days)
	return self.parent.parent.rest:request(
		Route(
			'guilds/%s/bans/%s',
			self.parent.id,
			self.id
		),
		{
			['delete-message-days'] = days or 0,
		},
		'PUT'	
	)
end

function Member:edit (config)
	return self.parent.parent.rest:request(
		Route(
			'guilds/%s/members/%s',
			self.parent.id,
			self.id
		),
		config,
		'PATCH'
	)
end
function Member:setNickname (nick)
	return self:edit({
		nick = nick,
	})
end
function Member:setMuted (mute)
	return self:edit({
		mute = mute,
	})
end
function Member:setDeaf (deaf)
	return self:edit({
		deaf = deaf,
	})
end
function Member:move (channel)
	channel = channel.id or channel
	return self:edit({
		channel_id = channel,
	})
end

function Member:setRole (role)
	role = role.id or role
	local roles = {role}
	for _,v in ipairs(self.roles) do
		if v.id == role then
			return true
		end
		table.insert(roles, v.id)
	end
	return self:edit({
		roles = roles,
	})
end
function Member:revokeRole (role)
	role = role.id or role
	local found
	local roles = {}
	for _,v in ipairs(self.roles) do
		if v.id == role then
			found = true
		else
			table.insert(roles, v.id)
		end
	end
	if not found then
		return true
	end
	return self:edit({
		roles = roles,
	})
end

function Member:hasPermission (bit)
	if self.parent.owner_id == self.id then
		return true
	end
	for _,role in ipairs(self.roles) do
		if role.permissions:has(bit) then
			return true
		end
	end
end

return Member