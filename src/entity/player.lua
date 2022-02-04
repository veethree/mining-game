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
    self.tileSize = data.tileSize
    self.speed = 150
    self.control = false

    self.reach = 6

    self.color = {0, 1, 1}


    self.inventory = {}

end

function entity:draw()
    if self.control then
        lg.setColor(self.color)
        lg.rectangle("fill", self.x, self.y, config.graphics.tileSize * scale_x, config.graphics.tileSize * scale_x)
    end

    --lg.rectangle("line", self.chunkX * self.tileSize * self.chunkSize, self.chunkY * self.tileSize * self.chunkSize, self.chunkSize * self.tileSize, self.chunkSize * self.tileSize)
    --lg.print(self.chunkX.."x"..self.chunkY, self.chunkX * self.tileSize * self.chunkSize, self.chunkY * self.tileSize * self.chunkSize)
end

return entity