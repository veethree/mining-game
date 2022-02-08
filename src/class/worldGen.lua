local worldGen = {}

function worldGen:load(data)
    -- World gen settings
    self.chunkSize = config.settings.chunkSize
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
    self.savePath = "/worlds/"..self.worldName
    fs.createDirectory(self.savePath)
    worldGen:saveWorld()
    worldGen:updateChunks(self.player.chunkX, self.player.chunkY)


    self.worldTick = 0
    self.worldTickRate = 2 -- Ticks per second
    print("WorldGen loaded")
end

function worldGen:saveWorld()
    self.worldConfig = {
        name = self.worldName,
        seed = self.seed,
        player = {
            x = self.player.gridX,
            y = self.player.gridY,
            inventory = self.player.inventory
        }
    }
    ttf.save(self.worldConfig, self.savePath.."/".."config.lua")
end

function worldGen:iterateChunks(func)
    for _, col in pairs(self.chunks) do
        for _, chunk in pairs(col) do
            func(chunk)
        end
    end
end


function worldGen:iterateTiles(func)
    for y, row in pairs(self.tiles) do
        for x, tile in pairs(row) do
            func(tile) 
        end
    end
end

function worldGen:centerPlayerOnTile(x, y)
    x = x or self.player.gridX
    y = y or self.player.gridY
    self.player.x = x * self.tileSize + (self.tileSize / 2)
    self.player.y = y * self.tileSize + (self.tileSize / 2) - (self.player.collisionBoxHeight / 2)
end

function worldGen:findPlayerSpawnTile()
    if not self.player.control then
        local spawnX, spawnY = 0, 0
        local foundSpawnTile = false
        if self.player.playerLoaded then
            spawnX = self.player.x
            spawnY = self.player.y
            foundSpawnTile = true
        else
            self:iterateChunks(function(chunk)
                for _, tile in ipairs(chunk.tiles) do
                    if tile.type == 2 then
                        spawnX = tile.y
                        spawnY = tile.x
                        foundSpawnTile = true
                        break
                    end
                end
            end)
        end

        if foundSpawnTile then
            self.player.control = true
            self.player:teleport(spawnX, spawnY)
            self:centerPlayerOnTile()
        end
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
                x = tile.gridX,
                y = tile.gridY,
                biome = tile.biome,
                type = tile.type,
                maxHP = tile.maxHP,
                hp = tile.hp,
                source = tile.source
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
        local tileX = v.x * self.tileSize
        local tileY = v.y * self.tileSize
        local tile = self.world:newEntity("src/entity/tile.lua", tileX, tileY, {x = tileX, y = tileY, type = v.type, biome = v.biome}) 
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
    self.player:updateChunkCoordinates()
    if self.player.chunkX ~= self.player.oChunkX or self.player.chunkY ~= self.player.oChunkY then
        self:updateChunks(self.player.chunkX, self.player.chunkY)
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
        self:saveWorld()
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

    -- World tick
    self.worldTick = self.worldTick + dt
    if self.worldTick > (1 / self.worldTickRate) then
        self:updateWorld()
        self.worldTick = 0
    end
end

function worldGen:updateWorld()
    self:iterateTiles(function(tile)
        -- Gathering adjescent tiles
        local adjescent = {}
        local adjescentCount = 0
        local adjescentCoords = {
            {x = tile.gridX + 1, y = tile.gridY},
            {x = tile.gridX - 1, y = tile.gridY},
            {x = tile.gridX, y = tile.gridY + 1},
            {x = tile.gridX, y = tile.gridY - 1},
        }

        for i,v in ipairs(adjescentCoords) do
            if self.tiles[v.y] then
                if self.tiles[v.y][v.x] then
                    adjescent[#adjescent+1] = self.tiles[v.y][v.x]
                    adjescentCount = adjescentCount + 1
                end
            end
        end

        local radiationDistance = 5
        if tile.type == 6 then
            local distance = fmath.distance(tile.gridX, tile.gridY, self.player.gridX, self.player.gridY)
            if distance < radiationDistance then
                self.player.radiation = self.player.radiation + (radiationDistance - distance) * 0.1
            else
                self.player.radiation = self.player.radiation - 0.01
                if self.player.radiation < 0 then self.player.radiation = 0 end
            end
        end

    end)
end

function worldGen:draw()

    if config.debug.showChunkBorders then
        camera:push()

        lg.setFont(font.regular)
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

        local showTiles = true
        if showTiles then
            lg.setColor(1, 0.5, 0)
            lg.setFont(font.tiny)
            for _, col in pairs(self.tiles) do
                for _, tile in pairs(col) do
                    lg.rectangle("line", tile.x + 1, tile.y + 1, tile.width, tile.height)
                    lg.print(tile.gridX.."x"..tile.gridY, tile.x, tile.y)
                end
            end
        end

        camera:pop()
    end
end

return worldGen