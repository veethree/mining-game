local button = {}
local button_meta = {__index = button}


function button.new(text, color, textColor, x, y, width, height, func)
    return setmetatable({
        text = text,
        color = color,
        textColor = textColor,
        x = x,
        y = y,
        width = width,
        height = height,
        func = func,
        buttonLeft = tiles[57],
        buttonCenter = tiles[58],
        buttonRight = tiles[59]
    }, button_meta)
end

function button:mouseOver()
    local mx, my = love.mouse.getPosition()
    return mx > self.x and mx < self.x + self.width and my > self.y and my < self.y + self.height or false
end

function button:draw()
    lg.setColor(self.color)
    -- Left
    lg.draw(tileAtlas, self.buttonLeft, self.x, self.y, 0, self.height / config.graphics.assetSize, self.height / config.graphics.assetSize)

    -- Center
    lg.draw(tileAtlas, self.buttonCenter, self.x + self.height, self.y, 0, (self.width - (self.height * 2)) / config.graphics.assetSize, self.height / config.graphics.assetSize)

    -- Right
    lg.draw(tileAtlas, self.buttonRight, self.x + self.width - self.height, self.y, 0, self.height / config.graphics.assetSize, self.height / config.graphics.assetSize)

    -- Text
    lg.setColor(self.textColor)
    local font = lg.getFont()
    local y = self.y + (self.height / 2) - ((font:getAscent() - font:getDescent()) / 2)
    lg.printf(self.text, self.x, y, self.width, "center")


    --lg.setColor(1, 0, 1)
    --lg.rectangle("line", self.x, self.y, self.width, self.height)
end

function button:mousepressed(x, y, k)
    if k == 1 and self:mouseOver() then
        if type(self.func) == "function" then
            self.func(self)
        end
    end
end

return button