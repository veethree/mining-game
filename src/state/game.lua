local game = {}

function game:load(data)
    lg.setBackgroundColor(0, 0, 0)
    local playerX, playerY = 0, 0 -- Grid coordinates!
    local playerLoaded = false -- True if player loaded from save file
    local playerInventory = {}
    if data.type == "new" then
        self.worldName = data.worldName
        self.seed = data.seed
        note:new("Created world '"..self.worldName.."'", "success")
    elseif data.type == "load" then
        local worldData = fs.load("worlds/"..data.worldName.."/config.lua")()
        self.worldName = worldData.name
        self.seed = worldData.seed
        playerX = worldData.player.x 
        playerY = worldData.player.y 
        playerLoaded = true

        playerInventory = worldData.player.inventory
        note:new("Loaded world '"..self.worldName.."'", "success")
    end

    -- Initializing the ECS world
    self.world = ecs.new()
    self.world:loadSystemFromFolder("src/system")

    --Exposing self.world for debug purposes
    if config.debug.enabled then
        _WORLD = self.world
    end

    -- Initializing player
    self.player = self.world:newEntity("src/entity/player.lua", playerX, playerY, {x = playerX, y = playerY, inventory = playerInventory, playerLoaded = playerLoaded})

    -- Expsing self.player for debug purposes
    _PLAYER = self.player

    -- Initializing worldGen
    worldGen:load({player = self.player, world = self.world, worldName = self.worldName, seed = self.seed})

    
    self.renderBuffer = worldGen.tileSize * 2
    self.hoverEntity = false -- Contains the entity the mouse is over, Used for mining
    self.time = 0 -- Timer used for shader animations

    -- Icon tile id's
    self.icon = {
        Coal = 1,
        Iron = 2,
        Gold = 3,
        Uranium = 4,
        Diamond = 5,
        Ruby = 6,
        Tanzenite = 7,
        health = 41,
        radiation = 42,
        Shrub = 9
    }

    -- Poster stuff
    self.canvas = poster.new()
    self.shaders = poster.newChain(
    {"chromaticAberrationRadius", "brightness", "contrast", "saturation", "vignette", "waveDistortion", "horizontalBlur"}, 
    {
        {"chromaticAberrationRadius", "position", {lg.getWidth() / 2, lg.getHeight() / 2}},
        {"chromaticAberrationRadius", "offset", 0 * scale_x},
        {"waveDistortion", "intensity", 0},
        {"waveDistortion", "scale", config.graphics.tileSize * scale_x * 0.5},
        {"waveDistortion", "phase", 0},
        {"brightness", "amount", 0.19},
        {"contrast", "amount", 1.2},
        {"saturation", "amount", 1.2},
        {"vignette", "radius", 1},
        {"vignette", "opacity", 1},
        {"vignette", "softness", 1},
        {"vignette", "color", {0, 0, 0}},
        {"horizontalBlur", "amount", 0},
    })

    self.shaders:addMacro("time", {
        {"waveDistortion", "phase", 1}
    })

    self.shaders:addMacro("rad", {
        {"chromaticAberrationRadius", "offset", 2},
        {"waveDistortion", "intensity", 0.0003},
    })

    self.bloom = poster.newChain(
        {"verticalBlur", "horizontalBlur"}, 
    {
        {"verticalBlur", "amount", 3},
        {"horizontalBlur", "amount", 3},
    })


end

function game:unload()
    ecs.unload()
    self.world = nil
end

function game:update(dt)
    -- Querying for visible entities
    self.visibleEntities = self.world:queryRect(camera.x - self.renderBuffer, camera.y - self.renderBuffer, lg.getWidth() + self.renderBuffer * 2, lg.getHeight() + self.renderBuffer * 2)

    -- Storing the entity the mouse is hovering over
    local mx, my = camera:getMouse()
    for i,v in ipairs(self.visibleEntities) do
        v.hover = false
        if fmath.pointInRect(mx, my, v.x, v.y, v.width, v.height) and fmath.distance(v.gridX, v.gridY, self.player.gridX, self.player.gridY) < self.player.reach then
            v.hover = true
            self.hoverEntity = v
        end

    end
    
    -- Updating camera
    camera:lookAtEntity(self.player)
    camera:update(dt)
    
    -- Updating world
    worldGen:update(dt)

    -- Internal timer used for shaders
    self.time = self.time + dt
    if self.time > math.pi * 2 then self.time = 0 end
    -- Settings macros
    self.shaders:setMacro("rad", self.player.radiation)
    self.shaders:setMacro("time", self.time)

    -- Mining
    if lm.isDown(1) and self.hoverEntity then
        self.player:mine(self.hoverEntity) 
    end
end

function game:drawHud()
    local iconScale = 50 * scale_x
    -- Health
    local x = lg.getWidth() * 0.01
    local y = lg.getHeight() * 0.01
    lg.setColor(1, 1, 1, 1)
    lg.draw(tileAtlas, tiles[self.icon["health"]], x, y, 0,  iconScale / config.graphics.assetSize, iconScale / config.graphics.assetSize)
    lg.setFont(font.large)
    local health = math.floor(self.player.health * 100) / 100
    lg.print(health, x * 6, y * 0.1)
    -- Radiation
    local x = lg.getWidth() * 0.01
    local y = lg.getHeight() * 0.1
    lg.setColor(1, 1, 1, 1)
    lg.draw(tileAtlas, tiles[self.icon["radiation"]], x, y, 0,  iconScale / config.graphics.assetSize, iconScale / config.graphics.assetSize)
    lg.setFont(font.large)
    local rad = math.floor(self.player.radiation * 100) / 100
    lg.print(rad, x * 6, y * 0.9)
    -- PLAYER INVENTORY
    local i = 0
    for k, v in pairs(self.player.inventory) do
        local x = lg.getWidth() * 0.95
        local y = lg.getHeight() - (lg.getHeight() * 0.08) * i
        lg.setColor(color.white)
        lg.draw(tileAtlas, tiles[self.icon[k]], x, y - 70 , 0, (config.graphics.tileSize * scale_x) / config.graphics.assetSize, (config.graphics.tileSize * scale_x) / config.graphics.assetSize)

        local r, g, b = unpack(color[k:lower()]) 
        lg.setFont(font.regular)
        
        setColor(0, 0, 0)
        lg.printf(v, -lg.getWidth() * 0.06, y * 0.92 + 1, lg.getWidth(), "right")
        lg.printf(v, -lg.getWidth() * 0.06, y * 0.92 - 1, lg.getWidth(), "right")
        lg.printf(v, -lg.getWidth() * 0.06 + 1, y * 0.92, lg.getWidth(), "right")
        lg.printf(v, -lg.getWidth() * 0.06 - 1, y * 0.92, lg.getWidth(), "right")

        setColor(255, 255, 255)
        lg.printf(v, -lg.getWidth() * 0.06, y * 0.92, lg.getWidth(), "right")
        i = i + 1
    end
end

function game:draw()
    self.canvas:set()
    lg.clear()
    camera:push()
    self.world:update(self.visibleEntities)
    self.player:draw()
    floatText:draw()
    camera:pop()
    self.canvas:unset()

    lg.setColor(1, 1, 1, 1)
    if config.graphics.useShaders then
        self.canvas:draw(self.shaders)

        lg.setBlendMode("add")
        lg.setColor(1, 1, 1, config.graphics.bloom)
        self.canvas:draw(self.bloom, self.bloom)
        lg.setBlendMode("alpha")
    else
        self.canvas:draw()
    end
   
    self:drawHud()


    if config.debug.enabled then
        lg.setColor(1, 0, 0)
        local all, all_len = self.world:query()
        local bumpItems = self.world:getBumpWorld():countItems()
        lg.setFont(font.tiny)
        lg.printf("FPS: "..love.timer.getFPS()..
        "\nEntities: "..#self.visibleEntities.."/"..all_len..
        "\nX: "..floor(self.player.x).." ("..self.player.gridX..") Y: "..floor(self.player.y).." ("..self.player.gridY..")"..
        "\nChunkX: "..self.player.chunkX.." ChunkY: "..self.player.chunkY..
        "\nLoaded chunks: "..worldGen.loadedChunkCount..
        "\nBump items: "..bumpItems..
        "\nWorld name: "..self.worldName.." World seed: "..tostring(self.seed), -12, 12, lg.getWidth(), "center")
        worldGen:draw()
    end


    -- DEBUG BUMP WORLD
    if config.debug.showCollision then
        camera:push()
        lg.setColor(0, 1, 1)
        local items, len = self.world:getBumpWorld():getItems()
        if len > 0 then
            for i,v in ipairs(items) do
                local x, y, w, h = self.world:getBumpWorld():getRect(v)
                lg.rectangle("line", x, y, w, h)
            end
        end
        camera:pop()
    end

    --self:drawMinimap(all)
end

function game:drawMinimap(all)
    -- Minimap
    local minimapScale = 4
    local minimapX = lg.getWidth() * 0.8
    local minimapY = lg.getHeight() * 0.8

    local miniMapColors = {
        {0, 0, 0, 1},
        {1, 1, 1, 1},
        {0.5, 0.5, 0.5},
        {0.8, 0.7, 0.5},
        {0.9, 0.9, 0.1},
        {0.1, 0.9, 0.1},
        {0.1, 0.7, 0.9},
        {0.9, 0.1, 0.1},
        {0.1, 0.1, 0.9},
        {0.1, 0.8, 0.9},
        {0.3, 0.8, 0.9},
        {0.3, 0.8, 0.9},
    }

    miniMapColors[0] = {1, 0, 0}
    
    local biomes = {
        {1, 0.6, 0.7},
        {0.1, 0.6, 0.3},
        {1, 0.3, 0.9},
        {1, 0.2, 0.2},
    }
    for i,v in ipairs(all) do
        if v.entityType == "tile" then
            if tonumber(v.type) then
                lg.setColor(miniMapColors[v.type])
                lg.rectangle("fill", minimapX + v.gridX * minimapScale - (self.player.gridX * minimapScale), minimapY + v.gridY * minimapScale - (self.player.gridY * minimapScale), minimapScale, minimapScale)
            end

            --lg.setColor(biomes[v.biome], biomes[v.biome], biomes[v.biome], 0.1)
            --lg.rectangle("line", minimapX + v.gridX * minimapScale - (self.player.gridX * minimapScale), minimapY + v.gridY * minimapScale - (self.player.gridY * minimapScale), minimapScale, minimapScale)
        elseif v.entityType == "player" then
            lg.setColor(0, 1, 0)
            lg.rectangle("fill", minimapX + v.gridX * minimapScale - (self.player.gridX * minimapScale), minimapY + v.gridY * minimapScale - (self.player.gridY * minimapScale), minimapScale, minimapScale)
        end
    end

end

function game:mousepressed(x, y, k)
    --local entity_list, len = self.world:queryRect(camera.x - self.renderBuffer, camera.y - self.renderBuffer, lg.getWidth() + self.renderBuffer * 2, lg.getHeight() + self.renderBuffer * 2)
    --for i,v in ipairs(entity_list) do
    --    if tonumber(v.type) then
    --        if v.maxHP and v.hover then
    --            v:mine()
    --        end
    --    end
    --end
end

function game:keypressed(key)
    if key == "f5" then
        worldGen:saveWorld()
    end
end

return game