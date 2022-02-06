local entity = {}

-- Data relating to different tile types
local tileData = {
    {
        type = "Wall",
        maxHP = 2,
        drop = {0, 0}
    },
    {
        type = "Floor",
        maxHP = false
    },
    {
        type = "Coal",
        maxHP = 2,
        drop = {3, 6}
    },
    {
        type = "Iron",
        maxHP = 10,
        drop = {1, 3}
    },
    {
        type = "Gold",
        maxHP = 5,
        drop = {1, 2}
    },
    {
        type = "Uranium",
        maxHP = 20,
        drop = {1, 1}
    },
    {
        type = "Diamond",
        maxHP = 15,
        drop = {1, 2}
    },
    {
        type = "Ruby",
        maxHP = 18,
        drop = {1, 1}
    },
    {
        type = "Tanzenite",
        maxHP = 30,
        drop = {1, 1}
    },
}

local biomes = {
    {1, 0.9, 0.9},
    {0.1, 0.6, 0.3},
    {1, 0.3, 0.9},
    {1, 0.2, 0.2},
}

function entity:load(data, ecs)
    self.bumpWorld = ecs.bumpWorld
    self.entityType = "tile"
    self.visible = true
    self.width = worldGen.tileSize
    self.height = worldGen.tileSize
    self.x = data.x--floor(data.x / self.width) * self.width
    self.y = data.y--floor(data.y / self.height) * self.height
    self.gridX = math.floor(self.x / floor(config.graphics.tileSize * scale_x))
    self.gridY = math.floor(self.y / floor(config.graphics.tileSize * scale_x))
    self.hover = false

    self.texture = data.texture or false
    self.type = data.type
    self.biome = data.biome

    -- Tile type data
    self.maxHP = false
    if tonumber(self.type) then
        if self.type > 0 then
            self.maxHP = tileData[self.type].maxHP
            self.hp = self.maxHP
            self.mined = false
        end
    end

    -- Collider tile
    if self.type == 1 then
        self.bumpWorld:add(self, self.x, self.y, self.width, self.height) 
    end
end

function entity:mine()
    if self.hp then
        self.hp = self.hp - 1
        if self.hp < 1 then
            if self.type > 2 then
                if not _PLAYER.inventory[tileData[self.type].type] then
                    _PLAYER.inventory[tileData[self.type].type] = 0
                end
                _PLAYER.inventory[tileData[self.type].type] = _PLAYER.inventory[tileData[self.type].type] + random(tileData[self.type].drop[1], tileData[self.type].drop[2])
            else
                self.bumpWorld:remove(self)
            end
            self.hp = false
            self.type = 2

            self.chunk.modified = true
        end
    end
end

function entity:draw()
    if _PLAYER and _PLAYER.control then
        -- Checking if tile is visible to player 
        local los =  bresenham.los(self.gridX, self.gridY, _PLAYER.gridX, _PLAYER.gridY, function(x, y)
            if worldGen.tiles[y] then
                if worldGen.tiles[y][x] then
                    if worldGen.tiles[y][x].type > 1 then
                        return true
                    end
               end
            end
            end)


        -- Calculating lighting
        local shade = 1
        if config.graphics.useLight then
            local distanceFromPlayer = fmath.distance(self.x, self.y, _PLAYER.x, _PLAYER.y)
            local maxDistance = config.graphics.lightDistance * scale_x

            shade = 1 - (1 / maxDistance) * distanceFromPlayer
            if shade < config.graphics.ambientLight then
                shade = config.graphics.ambientLight
            end
            if not los then
                shade = config.graphics.ambientLight
            end
        end

        if type(self.type) == "table" then
            lg.setColor(self.type[1], self.type[2], self.type[3], shade)
            lg.rectangle("fill", self.x, self.y, self.width, self.height)
        else
            lg.setColor(1, 1, 1, shade)
            lg.draw(tileAtlas, tiles[self.type + 16], self.x, self.y, 0, self.width / config.graphics.assetSize, self.height / config.graphics.assetSize)
            lg.setBlendMode("multiply", "premultiplied")
            lg.setColor(config.graphics.lightColor[1], config.graphics.lightColor[2], config.graphics.lightColor[3], shade)
            lg.rectangle("fill", self.x, self.y, self.width, self.height)
            lg.setBlendMode("alpha")
        end

        -- Selection
        self.hover = false
        local mx, my = camera:getMouse()
        if mx > self.x and mx < self.x + self.width and my > self.y and my < self.y + self.height then
            if fmath.distance(self.gridX, self.gridY, _PLAYER.gridX, _PLAYER.gridY) < _PLAYER.reach then
                self.hover = true
            end
        end

        if self.hover then
            lg.setBlendMode("add")
            lg.setColor(1, 1, 1, 1)
            lg.rectangle("line", self.x + 1, self.y + 1, self.width - 2, self.height - 2)
            lg.setBlendMode("alpha")
        end

        -- Breaking
        if self.hp then
            if self.hp < self.maxHP then
                local frame = #tileBreak - math.floor((#tileBreak / self.maxHP) * self.hp)
                lg.draw(tileBreakImg, tileBreak[frame], self.x, self.y, 0, self.width / config.graphics.assetSize, self.height / config.graphics.assetSize)
            end
        end

    end
end

return entity