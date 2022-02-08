-- TILE ENTITY
local entity = {}

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

    self:setType(data.type)

    self.color = {1, 1, 1}

    -- Creating bump item if solid
    if self.tileData.solid then
        self.bumpWorld:add(self, self.x, self.y, self.width, self.height) 
    end
end

function entity:setType(type)
    -- Housecleaning before changing type
    if not tileData[type].solid then
        if self.bumpWorld:hasItem(self) then
            self.bumpWorld:remove(self)
        end
    end

    -- Changing type
    self.type = type
    self.tileData = tileData[self.type]
    self.maxHP = self.tileData.maxHP
    self.hp = self.maxHP
    self.mined = false
end

function entity:mine()
    if self.tileData.destructible then
        self.hp = self.hp - 1
        if self.hp < 0 then
            local nextType = 2
            -- Drops
            local dropCount = random(self.tileData.drop[1], self.tileData.drop[2])
            if dropCount > 0 then
                if not _PLAYER.inventory[self.tileData.type] then
                    _PLAYER.inventory[self.tileData.type] = 0
                end
                _PLAYER.inventory[self.tileData.type] = _PLAYER.inventory[self.tileData.type] + dropCount
                floatText:new("+"..dropCount, self.x, self.y, font.regular, color[ self.tileData.type:lower() ])
            end

            -- If the mined tile is a wall, Maybe replace it with a gem
            if self.tileData.type == "Wall" then
                if random() < 0.05 then
                    nextType = wRand({80, 10, 10}) + 6
                end
            end

            self:setType(nextType)
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
                    if not worldGen.tiles[y][x].tileData.solid then
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

        -- Drawing tile
        lg.setColor(self.color)
        lg.draw(tileAtlas, tiles[self.tileData.textureID], self.x, self.y, 0, self.width / config.graphics.assetSize, self.height / config.graphics.assetSize)

        -- Drawing light
        lg.setBlendMode("multiply", "premultiplied")
        lg.setColor(config.graphics.lightColor[1], config.graphics.lightColor[2], config.graphics.lightColor[3], shade)
        lg.rectangle("fill", self.x, self.y, self.width, self.height)
        lg.setBlendMode("alpha")

        -- Drawing hover indicator
        if self.hover then
            lg.setBlendMode("add")
            lg.setColor(1, 1, 1, 1)
            lg.rectangle("line", self.x + 1, self.y + 1, self.width - 2, self.height - 2)
            lg.setColor(1, 1, 1, 0.1)
            lg.rectangle("fill", self.x + 1, self.y + 1, self.width - 2, self.height - 2)
            lg.setBlendMode("alpha")
        end

        -- Drawing breaking indicator
        if self.hp then
            if self.hp < self.maxHP then
                local frame = #tileBreak - math.floor((#tileBreak / self.maxHP) * self.hp)
                lg.setColor(1, 1, 1, 1)
                lg.draw(tileBreakImg, tileBreak[frame], self.x, self.y, 0, self.width / config.graphics.assetSize, self.height / config.graphics.assetSize)
            end
        end
    end
end

return entity