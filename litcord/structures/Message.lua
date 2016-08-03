local Message = class(structures.base)

function Message:__updated ()
	self.content_clean = self.content
	for i,v in ipairs(self.mentions) do
		self.mentions[i] = self.parent.parent.parent.users:get('id', v.id)
		self.content_clean = self.content_clean:gsub('<@'..v.id..'>', '@'..v.username)
		self.content_clean = self.content_clean:gsub('<@!'..v.id..'>', '@!'..v.username)
	end
	for mention in self.content_clean:gmatch('<@&.->') do -- role mentions
		local snowflake = mention:sub(3, #mention - 1)
		snowflake = tonumber(snowflake) or snowflake:sub(2) -- @!
		local role = self.parent.parent.roles:get('id', snowflake)
		role = (role and role.name) or snowflake
		self.content_clean = self.content_clean:gsub(mention, '#'..role)
	end
	for mention in self.content_clean:gmatch('<#.->') do -- channel mentions
		local snowflake = mention:sub(3, #mention - 1)
		snowflake = tonumber(snowflake) or snowflake:sub(2) -- @!
		local channel = self.parent.parent.parent.channels:get('id', snowflake)
		channel = (channel and channel.name) or snowflake
		self.content_clean = self.content_clean:gsub(mention, '#'..channel)
	end
end

function Message:reply (content, ...)
	if not self.parent.is_private then
		content = '<@!'..self.author.id..'> '..content
	end
	return self.parent:sendMessage(content, ...)
end

function Message:delete ()
	self.parent.parent.parent.rest:request(
		{
			method = 'DELETE',
			path = 'channels/'..self.parent.id..'/messages/'..self.id,
		}
	)
end

function Message:edit (content)
	self.parent.parent.parent.rest:request(
		{
			method = 'PATCH',
			path = 'channels/'..self.parent.id..'/messages/'..self.id,
			data = {
				content = content,
			},
		}
	)
end

return Message