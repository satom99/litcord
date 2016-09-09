local Member = class(structures.base)

function Member:__updated ()
	for i,v in ipairs(self.roles) do
		self.roles[i] = self.parent.roles:get('id', v)
	end
end

function Member:kick ()
	self.parent.parent.rest:request(
		{
			method = 'DELETE',
			path = 'guilds/'..self.parent.id..'/members/'..self.user.id,
		}
	)
end

function Member:ban (days)
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

function Member:edit (config)
	self.parent.parent.rest:request(
		{
			method = 'PATCH',
			path = 'guilds/'..self.parent.id..'/members/'..self.user.id,
			data = config,
		}
	)
end
function Member:move (channel)
	channel = tonumber(channel) or channel.id
	self:edit({
		channel_id = channel,
	})
end
function Member:setDeaf (deaf)
	self:edit({
		deaf = deaf,
	})
end
function Member:setMuted (mute)
	self:edit({
		mute = mute,
	})
end
function Member:setNickname (nick)
	self:edit({
		nick = nick,
	})
end

function Member:setRole (role)
	role = tonumber(role) or role.id
	local roles = {role}
	for _,v in ipairs(self.roles) do
		if v.id == role then
			return
		end
		table.insert(roles, v.id)
	end
	self:edit({
		roles = roles,
	})
end
function Member:revokeRole (role)
	role = tonumber(role) or role.id
	local found
	local roles = {}
	for _,v in ipairs(self.roles) do
		if v.id == role then
			found = true
			break
		else
			table.insert(roles, v.id)
		end
	end
	if not found then return end
	self:edit({
		roles = roles,
	})
end

function Member:hasPermission (bit)
	for _,role in ipairs(self.roles) do
		if role.permissions:has(bit) then
			return true
		end
	end
end

return Member