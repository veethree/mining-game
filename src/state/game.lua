local game = {}

function game:load(data)
    if data.type == "new" then
        self.worldName = data.worldName
        self.seed = data.seed
    elseif data.type == "load" then
        local worldData = fs.load("worlds/"..data.worldName.."/config.lua")()
        self.worldName = worldData.name
        self.seed = worldData.seed
    end


    self.world = ecs.new()
    self.world:loadSystemFromFolder("src/system")
    --Exposing self.world for debug purposes
    if config.debug.enabled then
        _WORLD = self.world
    end
    

    local px, py = lg.getWidth() / 2, lg.getHeight() / 2
    self.player = self.world:newEntity("src/entity/player.lua", px, py, {x = px, y = py})

    _PLAYER = self.player

    worldGen:load({player = self.player, world = self.world, worldName = self.worldName, seed = self.seed})
    self.renderBuffer = worldGen.tileSize * 2

    self.icon = {
        Coal = 1,
        Iron = 2,
        Gold = 3,
        Uranium = 4,
        Diamond = 5,
        Ruby = 6,
        Tanzenite = 7
    }

end

function game:unload()
    ecs.unload()
    self.world = nil
end

function game:update(dt)
    smoof:update(dt)
    camera:set(self.player.x - (lg.getWidth() / 2), self.player.y - (lg.getHeight() / 2))    
    camera:update(dt)
    worldGen:update(dt)
end

function game:draw()
    local entity_list, len = self.world:queryRect(camera.x - self.renderBuffer, camera.y - self.renderBuffer, lg.getWidth() + self.renderBuffer * 2, lg.getHeight() + self.renderBuffer * 2)
    camera:push()
    self.world:update(entity_list)


    self.player:draw()
    camera:pop()
    

    -- PLAYER INVENTORY
    local i = 0
    for k, v in pairs(self.player.inventory) do
        local x = 24 + ((config.graphics.tileSize * 1.3 ) * scale_x * i) 
        local y = lg.getHeight() - 40
        lg.draw(tileAtlas, tiles[self.icon[k]], x, y - 50 , 0, (config.graphics.tileSize * scale_x) / config.graphics.assetSize, (config.graphics.tileSize * scale_x) / config.graphics.assetSize)

        lg.setColor(1, 1, 1, 1)
        lg.printf(v, x + 10, y, lg.getWidth(), "left")
        i = i + 1
    end

    lg.setColor(1, 0.5, 0)
    local all, all_len = self.world:query()
    local bumpItems = self.world:getBumpWorld():countItems()
    lg.print("entities: "..len.."/"..all_len.."\nX: "..floor(self.player.x).." Y: "..floor(self.player.y).."\nBump items: "..bumpItems.."\nPlayer control: "..tostring(self.player.control), 12, 80)
    worldGen:draw()


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

    lg.setColor(1, 0, 0, 1)
end

function game:drawMinimap()
    -- Minimap
    local minimapScale = 4
    local minimapX = lg.getWidth() * 0.8
    local minimapY = lg.getHeight() * 0.8

    local miniMapColors = {
        {1, 1, 1, 1},
        {0.5, 0.5, 0.5},
        {0.8, 0.7, 0.5},
        {0.9, 0.9, 0.1},
        {0.1, 0.9, 0.1},
        {0.1, 0.7, 0.9},
        {0.9, 0.1, 0.1},
        {0.1, 0.1, 0.9},
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
    local entity_list, len = self.world:queryRect(camera.x - self.renderBuffer, camera.y - self.renderBuffer, lg.getWidth() + self.renderBuffer * 2, lg.getHeight() + self.renderBuffer * 2)
    for i,v in ipairs(entity_list) do
        if tonumber(v.type) then
            if v.maxHP and v.hover then
                v:mine()
            end
        end
    end
end

return game