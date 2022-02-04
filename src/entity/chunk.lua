local entity = {}

function entity:load(data, world)
    self.data = data
    self.visible = true
    self._TYPE = "chunk"
    self.x = data.xOffset
    self.y = data.yOffset
    self.worldX = (data.xOffset * data.chunkSize * data.tileSize)
    self.worldY = (data.yOffset * data.chunkSize * data.tileSize)
    self.width = data.chunkSize * data.tileSize
    self.height = data.chunkSize * data.tileSize
    self.tiles = {}
    self.world = world

    worldGenThread:start(data.xOffset, data.yOffset, data.chunkSize, data.tileSize)

    self.threadFinished = false
end

function entity:draw()
    -- Checking for data
    if not self.threadFinished then
        local tiles = love.thread.getChannel("worldGen"):pop()
        if tiles then
            for i,v in ipairs(tiles) do
                self.world:newEntity("src/entity/tile.lua", v.x, v.y, {x = v.x, y = v.y, color = v.color, width = self.data.tileSize, height = self.data.tileSize})
            end
            self.threadFinished = true
        end
    end
    lg.setColor(1, 0, 1)
    --lg.rectangle("line", self.worldX, self.worldY, self.width, self.height)
    if self._REMOVE then
        for i,v in ipairs(self.tiles) do
            v._REMOVE = true
        end
    end
end

return entity