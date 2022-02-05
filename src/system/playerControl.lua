return {
    filter = function(e)
        return e.control or false
    end,

    process = function(e, dt)
        local right, left, down, up = kb.isDown("d"), kb.isDown("a"), kb.isDown("s"), kb.isDown("w") 
        local space = kb.isDown("space")
        local speed = e.speed
        if space then speed = e.speed * 5 end

        e.moving = false
        if right then
            e.x = e.x + speed * dt
            e.moving = true
            e.direction = "right"
        elseif left then
            e.x = e.x - speed * dt
            e.moving = true
            e.direction = "left"
        end
        if down then
            e.y = e.y + speed * dt
            e.moving = true
            e.direction = "backward"
        elseif up then
            e.y = e.y - speed * dt
            e.moving = true
            e.direction = "forward"
        end

        e.gridX = math.floor(e.x / floor(config.graphics.tileSize * scale_x))
        e.gridY = math.floor(e.y / floor(config.graphics.tileSize * scale_x))

        e._SPATIAL.spatial:update_item_cell(e.x, e.y, e)
    end
}