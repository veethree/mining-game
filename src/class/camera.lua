-- A super basic camera module.
-- Handles basic camera movement, But limited to translation and zoom
-- Optionally can handle paralax scrolling with it's layer system.

local camera = {
    x = 0,
    y = 0,
    tx = 0,
    ty = 0,
    scale = 1,
    smoof = 5,
    layers = {}
}

local insert = table.insert
local remove = table.remove
local lg = love.graphics

-- Creates a new layer.
-- Scale: multiplier for the movement scale of the layer. Default is 1, 
-- Func: A drawing function for the layer
function camera:newLayer(scale, func)
    local layer = {
        scale = scale,
        func = func
    }
    insert(self.layers, layer)
end

function camera:push()
    lg.push()
    lg.translate(-math.floor(self.x), -math.floor(self.y))
    lg.scale(1 / self.scale, 1 / self.scale)
end

function camera:pop()
    lg.pop()
end

-- Moves the camera by x and y
function camera:move(x, y, dt)
    dt = dt or love.timer.getDelta()
    self.x = self.x + x * dt
    self.y = self.y + y * dt
end

function camera:lookAtEntity(ent, force)
    force = force or false
    local x = ent.x - (lg.getWidth() /  2) + (ent.width / 2)
    local y = ent.y - (lg.getHeight() /  2) + (ent.height / 2)
    self.tx = x
    self.ty = y
    if force then
        self.x = x
        self.y = y
    end
end

function camera:set(x, y)
    self.tx = x
    self.ty = y
end

function camera:update(dt)
    self.x = self.x + (self.tx - self.x) * self.smoof * dt
    self.y = self.y + (self.ty - self.y) * self.smoof * dt
end

function camera:getMouse()
	return love.mouse.getX() + self.x, love.mouse.getY() + self.y
end

function camera:getBoundingBox()
    return self.x, self.y, self.x + lg.getWidth(), self.y + lg.getHeight()
end

function camera:draw()
    local base_x, base_y = self.x, self.y
    for _, layer in ipairs(self.layers) do
        self.x = base_x * layer.scale
        self.y = base_y * layer.scale
        self:push()
        layer.func()
        self:pop()
    end
    self.x = base_x
    self.y = base_y
end

return camera