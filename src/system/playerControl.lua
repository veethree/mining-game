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
        local xOffset = (e.collisonBoxWidth / 2)
        local nx, ny = e.x - xOffset, e.y 
        if right then
            nx = nx + speed * dt
            e.moving = true
        elseif left then
            nx = nx - speed * dt
            e.moving = true
        end
        if down then
            ny = ny + speed * dt
            e.moving = true
        elseif up then
            ny = ny - speed * dt
            e.moving = true
        end


        -- Collisions
        local fx, fy, col, len = e.bumpWorld:move(e, nx, ny)

        if not config.debug.playerCollision then
            fx, fy = nx, ny
        end

        if len > 0 then
            e.moving = false
        end
        e.x = fx + xOffset
        e.y = fy 

        e:updateGridCoordinates()

        e._SPATIAL.spatial:update_item_cell(e.x, e.y, e)
    end
}