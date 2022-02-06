local entity = {}

function entity:load(data, ecs)
    self.bumpWorld = ecs.bumpWorld
    self.entityType = "player"
    self.visible = false
    self.x = data.x--floor(data.x / self.width) * self.width
    self.y = data.y--floor(data.y / self.height) * self.height
    self.gridX = 0
    self.gridY = 0
    self.chunkX = 0
    self.chunkY = 0
    self.oChunkX = 0
    self.oChunkY = 0
    self.chunkSize = data.chunkSize
    self.tileSize = math.floor(config.graphics.tileSize * scale_x)
    self.collisonBoxWidth = math.floor(config.graphics.tileSize * scale_x * 0.8)
    self.collisionBoxHeight = math.floor(config.graphics.tileSize * scale_x * 0.6)
    self.speed = 100 * scale_x
    self.control = false

    self.reach = 6

    self.color = {1, 1, 1}

    self.animation = {
        right = anim.new("src/assets/player/left.png", config.graphics.assetSize, config.graphics.assetSize),
        left = anim.new("src/assets/player/right.png", config.graphics.assetSize, config.graphics.assetSize),
        forward = anim.new("src/assets/player/backward.png", config.graphics.assetSize, config.graphics.assetSize),
        backward = anim.new("src/assets/player/forward.png", config.graphics.assetSize, config.graphics.assetSize),
    }
    self.moving = false
    self.direction = "right"

    self.inventory = {}

    self.bumpWorld:add(self, self.x, self.y, self.collisonBoxWidth, self.collisionBoxHeight)

end

function entity:teleport(x, y)
    self.x = x
    self.y = y
    self.bumpWorld:update(self, self.x, self.y)
end

function entity:draw()
    if self.control then
        lg.setColor(self.color)
        --lg.rectangle("fill", self.x, self.y, config.graphics.tileSize * scale_x, config.graphics.tileSize * scale_x)
        if self.moving then
            self.animation[self.direction]:start()
            self.animation[self.direction]:update(love.timer.getDelta())
        else
            self.animation[self.direction]:stop()
        end
        local x = self.x - (self.tileSize - self.collisonBoxWidth) / 2
        local y = self.y - (self.tileSize - self.collisionBoxHeight)
        self.animation[self.direction]:draw(x, y, self.tileSize / config.graphics.assetSize, self.tileSize / config.graphics.assetSize)

    end
end

return entity