-- Various utility functions
function wRand(weights)
    local weightSum = 0
    for i,v in ipairs(weights) do weightSum = weightSum + v end
    local target = weightSum * random()
    local rSum = 0
    for i,v in ipairs(weights) do
        rSum = rSum + v
        if rSum > target then
            return i
        end
    end
end

function require_folder(folder)
    if fs.getInfo(folder) then
        for i,v in ipairs(fs.getDirectoryItems(folder)) do
            if fs.getInfo(folder.."/"..v).type == "directory" then
                _G[v] = require(folder.."."..v)
            else
                if get_file_type(v) == "lua" then
                    _G[get_file_name(v)] = require(folder.."."..get_file_name(v))
                end
            end
        end
    else
        error(string.format("Folder '%s' does not exists", folder))
    end
end

function hasValue(t, val)
    for k,v in pairs(t) do
        if v == val then return true end
    end
end

function get_file_type(file_name)
    return string.match(file_name, "%..+"):sub(2)
end

function get_file_name(file_name)
    return string.match(file_name, ".+%."):sub(1, -2) 
end

-- Converts colors from 0-255 to 0-1
function convertColor(r, g, b, a)
    a = a or 255
    return r / 255,  g / 255,  b / 255,  a / 255
end

function loadAtlas(path, tileWidth, tileHeight, padding)
	if not love.filesystem.getInfo(path) then
		error("'"..path.."' doesn't exist.")
	end

	local a = {}
	local img = love.graphics.newImage(path)
	local width = math.floor(img:getWidth() / tileWidth)
	local height = math.floor(img:getHeight() / tileHeight)
		
	local x, y = padding, padding
	for i=1, width * height do
		a[i] = love.graphics.newQuad(x, y, tileWidth, tileHeight, img:getWidth(), img:getHeight())
		x = x + tileWidth + padding
		if x > ((width-1) * tileWidth) then
			x = padding
			y = y + tileHeight + padding
		end
	end

	return img, a
end