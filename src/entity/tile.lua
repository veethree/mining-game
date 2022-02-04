local entity = {}

local tileData = {
    {
        type = "Stone",
        maxHP = false
    },
    {
        type = "Coal",
        maxHP = 3,
        drop = {3, 6}
    },
    {
        type = "Diamond",
        maxHP = 10,
        drop = {1, 3}
    },
    {
        type = "Iron",
        maxHP = 5,
        drop = {1, 3}
    },
    {
        type = "Ruby",
        maxHP = 20,
        drop = {1, 1}
    },
}

function entity:load(data)
    self.visible = true
    self.width = worldGen.tileSize
    self.height = worldGen.tileSize
    self.x = data.x--floor(data.x / self.width) * self.width
    self.y = data.y--floor(data.y / self.height) * self.height
    self.gridX = math.floor(self.x / floor(config.graphics.tileSize * scale_x))
    self.gridY = math.floor(self.y / floor(config.graphics.tileSize * scale_x))
    self.hover = false

    self.texture = data.texture or false
    self.type = data.color
    self.biome = data.biome
    print(self.biome)

    -- Tile type data
    self.maxHP = false
    if tonumber(self.type) then
        self.maxHP = tileData[self.type].maxHP
        self.hp = self.maxHP
        self.mined = false
    end
end

function entity:mine()
    if self.hp then
        self.hp = self.hp - 1
        if self.hp < 1 then
            if not _PLAYER.inventory[tileData[self.type].type] then
            _PLAYER.inventory[tileData[self.type].type] = 0
            end

            _PLAYER.inventory[tileData[self.type].type] = _PLAYER.inventory[tileData[self.type].type] + random(tileData[self.type].drop[1], tileData[self.type].drop[2])
            self.hp = false
            self.type = 1
        end
    end
end

function entity:draw()
    --lg.setColor(self.color)
    --lg.rectangle("fill", self.x, self.y, self.width, self.height)
    -- Selection
    self.hover = false
    local mx, my = camera:getMouse()
    if mx > self.x and mx < self.x + self.width and my > self.y and my < self.y + self.height then
        if fmath.distance(self.gridX, self.gridY, _PLAYER.gridX, _PLAYER.gridY) < _PLAYER.reach then
            self.hover = true
        end
    end

    if _PLAYER then

        -- Checking if tile is visible to player via bresenham.lua hopefully we will see if this even works lol say hi to your mom for me
        local los =  bresenham.los(self.gridX, self.gridY, _PLAYER.gridX, _PLAYER.gridY, function(x, y)
            if worldGen.tiles[y] then
                if worldGen.tiles[y][x] then
                    return true
               end
            end
            end)


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
            if self.biome == 2 then
                lg.setColor(0, 0, 1, shade)
            end
            lg.draw(tileAtlas, tiles[self.type], self.x, self.y, 0, self.width / config.graphics.assetSize, self.height / config.graphics.assetSize)
            lg.setBlendMode("multiply", "premultiplied")
            lg.setColor(config.graphics.lightColor[1], config.graphics.lightColor[2], config.graphics.lightColor[3], shade)
            lg.rectangle("fill", self.x, self.y, self.width, self.height)
            lg.setBlendMode("alpha")

        end

        if self.hover then
            lg.setBlendMode("add")
            lg.setColor(1, 1, 1, 1)
            lg.rectangle("line", self.x + 1, self.y + 1, self.width - 2, self.height - 2)
            lg.setBlendMode("alpha")
        end

        local a = 0
        if self.hp then
            a = 1 - (1 / self.maxHP) * self.hp
            lg.setBlendMode("add")
            lg.setColor(1, 1, 1, a)
            lg.rectangle("fill", self.x, self.y, self.width, self.height)
            lg.setBlendMode("alpha")
        end

    end
end

return entity