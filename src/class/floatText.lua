-- NOTE: This takes colors in the range 0-255!
local floatText = {
    list = {}
}

function floatText:new(text, x, y, _font, color, time)
    self.list[#self.list+1] = {
        text = text,
        x = x,
        y = y,
        font = _font or font.regular,
        color = color or {1, 1, 1},
        alpha = 0,
        time = time or 1,
        remove = false
    }
    smoof:new(self.list[#self.list], {alpha = 1})
end

function floatText:update(dt)
    for i,v in ipairs(self.list) do
        v.time = v.time - dt
        if v.time < 0 and not v.remove then
            --(object, target, smoof_value, completion_threshold, bind, callbacks
            smoof:new(v, {alpha = 0, y = v.y - (lg.getHeight() * 0.01)}, nil, nil, nil, {onArrive = function() table.remove(self.list, i) end})
            v.remove = true
        end 
    end
end

function floatText:draw()
    for i,v in ipairs(self.list) do
        -- Shadow
        lg.setColor(0, 0, 0, v.alpha)
        lg.setFont(v.font)
        lg.print(v.text, v.x, v.y + ((v.font:getAscent() - v.font:getDescent()) * 0.1 ))
        --Text
        local r, g, b = unpack(v.color)
        setColor(r, g, b, v.alpha * 255)
        lg.setFont(v.font)
        lg.print(v.text, v.x, v.y)
    end

end


return floatText