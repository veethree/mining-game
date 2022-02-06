local worldGen = {}

function worldGen:load(data)
    -- World gen settings
    self.chunkSize = 6
    self.tileSize = floor(config.graphics.tileSize * scale_x)
    self.renderDistance = 3 -- How many chunks in each direction to generate at a time
    self.maxChunkDistance = self.renderDistance * 2 -- How far, In chunk coordinates before a chunk is unloaded

    self.chunkSaveTick = 0

    self.player = data.player
    self.world = data.world
    self.worldName = data.worldName
    self.seed = data.seed

    self.chunks = {} -- Loaded chunks
    self.tiles = {} -- Loaded tiles, Used for LOS 
    self.loadedChunkCount = 0

    self.thread = lt.newThread("src/class/generateChunk.lua") -- Thread used for generating chunks
    -- File management
    -- Creating save directory for world
    fs.createDirectory("worlds/"..self.worldName)

    self.worldConfig = {
        name = self.worldName,
        seed = self.seed
    }
    ttf.save(self.worldConfig, "worlds/"..self.worldName.."/config.lua")
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
                if tile.type == 2 then
                    spawnX = tile.x
                    spawnY = tile.y
                    break
                end
            end
            self.player:teleport(spawnX, spawnY)
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

    self.thread:start(chunksToGenerate, self.chunkSize, self.tileSize, self.seed)
end

-- Stores a chunk in a file
function worldGen:saveChunkToFile(chunk)
    if config.debug.saveChunks then
        if not fs.getInfo("worlds/"..self.worldName.."/chunks") then
            fs.createDirectory("worlds/"..self.worldName.."/chunks") 
        end
        local outputName = "worlds/"..self.worldName.."/chunks/("..chunk.x..")("..chunk.y..").lua"
        local output = {
            x = chunk.x,
            y = chunk.y,
            modified = true,
            tiles = {}
        }
        for i, tile in ipairs(chunk.tiles) do
            output.tiles[i] = {
                x = tile.x,
                y = tile.y,
                biome = tile.biome,
                type = tile.type,
                maxHP = tile.maxHP,
                hp = tile.hp
            }
        end

        ttf.save(output, outputName)
        print("Saving chunk "..chunk.x.."x"..chunk.y.." to disk.")
    end
end

function worldGen:loadChunkFromFile(x, y)
    local fileName = "worlds/"..self.worldName.."/chunks/("..x..")("..y..").lua"
    if not fs.getInfo(fileName) then
        return false
    end    

    print("Loading chunk "..x.." x "..y.." from disk.")
    local chunk = fs.load(fileName)()
    if not self.chunks[chunk.y] then self.chunks[chunk.y] = {} end
    if self.chunks[chunk.y][chunk.x] then
        for i,v in ipairs(self.chunks[chunk.y][chunk.x].tiles) do
            v._REMOVE = true
        end
    end
    self.chunks[chunk.y][chunk.x] = {
        x = chunk.x,
        y = chunk.y,
        modified = true,
        tiles = {}
    }

    for i,v in ipairs(chunk.tiles) do
        local tile = self.world:newEntity("src/entity/tile.lua", v.x, v.y, {x = v.x, y = v.y, type = v.type, biome = v.biome}) 
        tile.chunk = self.chunks[chunk.y][chunk.x]
        self.chunks[chunk.y][chunk.x].tiles[#self.chunks[chunk.y][chunk.x].tiles + 1] = tile

        if not self.tiles[tile.gridY] then
            self.tiles[tile.gridY] = {}
        end

        self.tiles[tile.gridY][tile.gridX] = tile
    end
end

function worldGen:chunkFileExists(x, y)
    return fs.getInfo("worlds/"..self.worldName.."/chunks/("..x..")("..y..").lua") and true or false
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
        if self:chunkFileExists(chunk.x, chunk.y) then
            self:loadChunkFromFile(chunk.x, chunk.y)
        else
            if not self.chunks[chunk.y] then self.chunks[chunk.y] = {} end
            if self.chunks[chunk.y][chunk.x] == nil then
                self.chunks[chunk.y][chunk.x] = {
                    x = chunk.x,
                    y = chunk.y,
                    modified = false,
                    tiles = {}
                }
                for i,v in ipairs(chunk.tiles) do
                    local tile = self.world:newEntity("src/entity/tile.lua", v.x, v.y, {x = v.x, y = v.y, type = v.type, biome = v.biome}) 
                    tile.chunk = self.chunks[chunk.y][chunk.x]
                    self.chunks[chunk.y][chunk.x].tiles[#self.chunks[chunk.y][chunk.x].tiles + 1] = tile

                    if not self.tiles[tile.gridY] then
                        self.tiles[tile.gridY] = {}
                    end

                    self.tiles[tile.gridY][tile.gridX] = tile
                end
            end
        end
    end

    -- Unloading chunkers
    local chunksToUnload = 0
    local save = false
    self.chunkSaveTick = self.chunkSaveTick + dt
    if self.chunkSaveTick > config.settings.chunkSaveInterval then
        save = true 
        self.chunkSaveTick = 0
    end
    for y,col in pairs(self.chunks) do
        for x, chunk in pairs(col) do
            -- Saving chunk if modified
            if chunk.modified and save then
                self:saveChunkToFile(chunk)
            end
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

        for _, col in pairs(self.chunks) do
            for _, chunk in pairs(col) do
                lg.setColor(1, 1, 0)
                if chunk.modified then
                    lg.setColor(1, 0, 1)
                end
                lg.print(chunk.x.." x "..chunk.y.."\nModified: "..tostring(chunk.modified), chunk.x * self.chunkSize * self.tileSize + self.tileSize, chunk.y * self.chunkSize * self.tileSize + self.tileSize)

                lg.rectangle("line", chunk.x * self.chunkSize * self.tileSize + self.tileSize, chunk.y * self.chunkSize * self.tileSize + self.tileSize, self.chunkSize * self.tileSize, self.chunkSize * self.tileSize) 
            end
        end

        lg.setColor(0, 1, 1)
        for _, col in pairs(self.tiles) do
            for _, tile in pairs(col) do
                lg.rectangle("line", tile.x + 1, tile.y + 1, tile.width, tile.height)
            end
        end

        camera:pop()
    end
end

return worldGen