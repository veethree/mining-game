local game = {}

function game:load(data)
    self.world = ecs.new()
    self.world:loadSystemFromFolder("src/system")
    --Exposing self.world for debug purposes
    if config.debug.enabled then
        _WORLD = self.world
    end
    

    local px, py = lg.getWidth() / 2, lg.getHeight() / 2
    self.player = self.world:newEntity("src/entity/player.lua", px, py, {x = px, y = py})

    _PLAYER = self.player

    worldGen:load({player = self.player, world = self.world})
    self.renderBuffer = worldGen.tileSize * 2
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


    local i = 0
    for k, v in pairs(self.player.inventory) do
        lg.printf(k..": "..v, -12, 24 + 24 * i, lg.getWidth(), "right")
        i = i + 1
    end

    lg.setColor(1, 0.5, 0)
    local all, all_len = self.world:query()
    lg.print("entities: "..len.."/"..all_len.."\nX: "..floor(self.player.x).." Y: "..floor(self.player.y), 12, 24)
    worldGen:draw()

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