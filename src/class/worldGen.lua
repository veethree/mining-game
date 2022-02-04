local worldGen = {}

function worldGen:load(data)
    -- World gen settings
    self.chunkSize = 6
    self.tileSize = config.graphics.tileSize * scale_x
    self.renderDistance = 2 -- How many chunks in each direction to generate at a time
    self.maxChunkDistance = 6 -- How far, In chunk coordinates before a chunk is unloaded


    self.player = data.player
    self.world = data.world

    self.chunks = {} -- Loaded chunks
    self.tiles = {} -- Loaded tiles, Used for LOS 
    self.loadedChunkCount = 0

    self.thread = lt.newThread("src/class/generateChunk.lua") -- Thread used for generating chunks
end

function worldGen:iterateChunks(func)
    for _, col in pairs(self.chunks) do
        for _, chunk in pairs(col) do
            func(chunk)
        end
    end
end

function worldGen:findPlayerSpawnTile()
    if not self.player.control then
        self:iterateChunks(function(chunk)
            local spawnX, spawnY = 0, 0
            for _, tile in ipairs(chunk.tiles) do
                if tile.type == 1 then
                    spawnX = tile.x
                    spawnY = tile.y
                    break
                end
            end
            self.player.x = spawnX
            self.playerY = spawnY
            self.player.control = true      
        end)
    end
end

-- A callback function, Called everytime the player enters a new chunk
-- Checks what chunks should be loeaded right now, And loads/unloads chunks as needed.
function worldGen:updateChunks(chunkX, chunkY)
    local px, py = self.player.chunkX, self.player.chunkY

    local expectedChunks = {}
    for y=-self.renderDistance, self.renderDistance do
        for x=-self.renderDistance, self.renderDistance do
            expectedChunks[#expectedChunks+1] = {x = px + x, y = py + y}
        end
    end

    local chunksToGenerate = {}

    for i,v in ipairs(expectedChunks) do
        local exists = false
        if self.chunks[v.y] then
            if self.chunks[v.y][v.x] then
                exists = true
            end 
        end
        
        if not exists then
            chunksToGenerate[#chunksToGenerate+1] = {
                x = v.x, y = v.y
            }
        end
    end

    print("Generating "..#chunksToGenerate.." chunks. Spawning ~"..#chunksToGenerate * 36 .." tile entities")

    self.thread:start(chunksToGenerate, self.chunkSize, self.tileSize, seed)
end

function worldGen:update(dt)
    -- Checking if player has entered a new chunk
    self.player.chunkX = floor(self.player.x / (self.chunkSize * self.tileSize))
    self.player.chunkY = floor(self.player.y / (self.chunkSize * self.tileSize))

    if self.player.chunkX ~= self.player.oChunkX or self.player.chunkY ~= self.player.oChunkY then
        self:updateChunks(self.player.chunkX, self.player.chunkY)
        self.player.oChunkX = self.player.chunkX 
        self.player.oChunkY = self.player.chunkY
    end

    -- Thread shit
    local chunk = lt.getChannel("worldGen"):pop()
    if chunk then
        if not self.chunks[chunk.y] then self.chunks[chunk.y] = {} end
        if self.chunks[chunk.y][chunk.x] == nil then
            self.chunks[chunk.y][chunk.x] = {
                x = chunk.x,
                y = chunk.y,
                tiles = {}
            }
            for i,v in ipairs(chunk.tiles) do
                local tile = self.world:newEntity("src/entity/tile.lua", v.x, v.y, {x = v.x, y = v.y, color = v.color}) 
                self.chunks[chunk.y][chunk.x].tiles[#self.chunks[chunk.y][chunk.x].tiles + 1] = tile

                if not self.tiles[tile.gridY] then
                    self.tiles[tile.gridY] = {}
                end

                self.tiles[tile.gridY][tile.gridX] = tile
            end
        end
    end

    -- Unloading chunkers
    local chunksToUnload = 0
    for y,col in pairs(self.chunks) do
        for x, chunk in pairs(col) do
            if fmath.distance(self.player.chunkX, self.player.chunkY, x, y) > self.maxChunkDistance then
                for i,v in ipairs(chunk.tiles) do
                    self.tiles[v.gridY][v.gridX] = nil
                    v._REMOVE = true
                end
                self.chunks[y][x] = nil
                chunksToUnload = chunksToUnload + 1
            end
        end
    end

    if chunksToUnload > 0 then
        print("Unloading "..chunksToUnload.." chunks")
    end

    --Counting loaded chunks
    self.loadedChunkCount = 0
    self:iterateChunks(function(chunk)
       self.loadedChunkCount = self.loadedChunkCount + 1
    end)

    -- Spawning player
    self:findPlayerSpawnTile()

end

function worldGen:draw()
    lg.print("Loaded Chunks: "..self.loadedChunkCount, 12, 48)

    if config.debug.showChunkBorders then
        camera:push()
        lg.setColor(1, 1, 0)
        for _, col in pairs(self.chunks) do
            for _, chunk in pairs(col) do
                lg.rectangle("line", chunk.x * self.chunkSize * self.tileSize + self.tileSize, chunk.y * self.chunkSize * self.tileSize + self.tileSize, self.chunkSize * self.tileSize, self.chunkSize * self.tileSize) 
            end
        end

        lg.setColor(0, 1, 1)
        for _, col in pairs(self.tiles) do
            for _, tile in pairs(col) do
                lg.print(tile.gridX.."x"..tile.gridY, tile.x + 1, tile.y + 1)
            end
        end

        camera:pop()
    end
end

return worldGen