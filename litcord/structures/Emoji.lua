local base = require('litcord.structures.base')

local Emoji = class(base)

function Emoji:__updated ()
	if not self.id then
		-- default emojis
	else
		self.string = '<:'..self.name..':'..self.id..'>'
		self.url = 'https://cdn.discordapp.com/emojis/'..self.id..'.png'
	end
end

return Emoji