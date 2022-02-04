return {
    filter = function(e)
        return e.control or false
    end,

    process = function(e, dt)
        local right, left, down, up = kb.isDown("d"), kb.isDown("a"), kb.isDown("s"), kb.isDown("w") 
        local space = kb.isDown("space")
        local speed = e.speed
        if space then speed = e.speed * 5 end
        if right then
            e.x = e.x + speed * dt
        elseif left then
            e.x = e.x - speed * dt
        end
        if down then
            e.y = e.y + speed * dt
        elseif up then
            e.y = e.y - speed * dt
        end

        e.gridX = math.floor(e.x / config.graphics.tileSize * scale_x)
        e.gridY = math.floor(e.y / config.graphics.tileSize * scale_x)

        e._SPATIAL.spatial:update_item_cell(e.x, e.y, e)
    end
}