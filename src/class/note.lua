local note = {
    notifications = {},
    color = {
        default = {1, 1, 1},
        important = {0.1, 0.5, 1},
        success = {0, 1, 0},
        danger = {1, 0, 0}
    }
}

function note:new(text, color, time)
    self.notifications[#self.notifications+1] = {
        text = text,
        color = color or "default",
        time = time or 2
    } 
end


function note:update(dt)
    for i,v in ipairs(self.notifications) do
        v.time = v.time - dt
        if v.time < 0 then
            table.remove(self.notifications, i)
        end
    end
end

function note:draw()
    lg.setFont(font.regular)
    for i,v in ipairs(self.notifications) do
        lg.setColor(self.color[v.color])
        local x = -(lg.getWidth() * 0.05)
        local y = -(lg.getHeight() * 0.01) + (lg.getHeight() * 0.05) * i
        lg.printf(v.text, x, y, lg.getWidth(), "right")
    end
end

return note