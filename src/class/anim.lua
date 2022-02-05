-- A minimal animation library
local anim = {}
local anim_meta = {__index = anim}

local function loadAtlas(path, tileWidth, tileHeight, padding)
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
		if x > (width * tileWidth) then
			x = padding
			y = y + tileHeight + padding
		end
	end

	return img, a
end

function anim.new(path, tileWidth, tileHeight, padding)
    padding = padding or 0
    local img, frames = loadAtlas(path, tileWidth, tileHeight, padding)
    return setmetatable({
        image = img,
        frames = frames,
        currentFrame = 1,
        frameTime = 0.1,
        tick = 0,
        play = false
    }, anim_meta)
end

function anim:start(reset)
    if reset then self:reset() end
    self.play = true
end

function anim:stop()
    self.play = false
end

function anim:reset()
    self.currentFrame = 1
end

function anim:setFrameTime(frameTime)
    if type(frameTime) == "table" then
        assert(#frameTime == #self.frames, "The frameTime table length must match the frames in the animation")
    end
    self.frameTime = frameTime
end

function anim:setFrame(frame)
    self.currentFrame = frame
    if self.currentFrame > #self.frames then
        self.currentFrame = #self.frames
    elseif self.currentFrame < 1 then
        self.currentFrame = 1
    end
end

function anim:update(dt)
    if self.play then
        self.tick = self.tick + dt

        local frameTime
        if type(self.frameTime) == "table" then
            frameTime = self.frameTime[self.currentFrame] 
        elseif type(self.frameTime) == "number" then
            frameTime = self.frameTime
        end
        if self.tick > frameTime then
            self.currentFrame = self.currentFrame + 1
            if self.currentFrame > #self.frames then
                self.currentFrame = 1
            end 
            self.tick = 0
        end
    end
end

function anim:draw(x, y, scaleX, scaleY)
    lg.draw(self.image, self.frames[self.currentFrame], math.floor(x), math.floor(y), 0, scaleX, scaleY) 
end

return anim