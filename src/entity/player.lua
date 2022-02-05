local entity = {}

function entity:load(data)
    self.visible = false
    self.x = data.x--floor(data.x / self.width) * self.width
    self.y = data.y--floor(data.y / self.height) * self.height
    self.chunkX = 0
    self.chunkY = 0
    self.oChunkX = 0
    self.oChunkY = 0
    self.chunkSize = data.chunkSize
    self.tileSize = config.graphics.tileSize * scale_x
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
        self.animation[self.direction]:draw(self.x, self.y, self.tileSize / config.graphics.assetSize, self.tileSize / config.graphics.assetSize)

    end

    --lg.rectangle("line", self.chunkX * self.tileSize * self.chunkSize, self.chunkY * self.tileSize * self.chunkSize, self.chunkSize * self.tileSize, self.chunkSize * self.tileSize)
    --lg.print(self.chunkX.."x"..self.chunkY, self.chunkX * self.tileSize * self.chunkSize, self.chunkY * self.tileSize * self.chunkSize)
end

return entity