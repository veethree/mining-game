local entity = {}

function entity:load(data, world)
    self.width = data.width
    self.height = data.height
    self.x = data.x--floor(data.x / self.width) * self.width
    self.y = data.y--floor(data.y / self.height) * self.height

    self.texture = data.texture or false
    self.color = data.color

end

function entity:draw()
    lg.setColor(self.color)
    lg.rectangle("fill", self.x, self.y, self.width, self.height)
end

return entity