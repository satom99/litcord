File = Class()

function File:Write(text, path, mode)
	assert(type(text) == "string" and type(path) == "string" and (not mode or type(mode) == "string"), "WriteFile: wrong argument types (<string> expected for text, path and mode)")
	local file = io.open(path, mode or "w+")
	file:write(text)
	file:close()
	return true
end

function File:GetSize(path)
	assert(type(path) == "string", "GetFileSize: wrong argument types (<string> expected for path)")
	local file = io.open(path, "r")
	local size = file:seek("end")
	file:close()
	return size
end

function File:Read(path)
	assert(type(path) == "string", "ReadFile: wrong argument types (<string> expected for path)")
	local file = io.open(path, "r")
	local text = file:read("*all")
	file:close()
	return text
end

function File:Exist(path)
	assert(type(path) == "string", "FileExist: wrong argument types (<string> expected for path)")
	local file = io.open(path, "r")
	if file then file:close() return true else return false end
end

return File
