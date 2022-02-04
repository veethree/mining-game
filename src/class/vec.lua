local vec = {}
local vm = {__index = vec}

function vec.new(x, y)
	x = x or 0
	y = y or 0
	local v = {
		x = x,
		y = y
	}
	return setmetatable(v, vm)
end

function vec.subtract(v1, v2)
	local v = vec.new()
	v.x = v1.x - v2.x
	v.y = v1.y - v2.y
	return v
end

function vec.add(v1, v2)
	local v = vec.new()
	v.x = v1.x + v2.x
	v.y = v1.y + v2.y
	return v
end

function vec.multiply(v1, v2)
	local v = vec.new()
	v.x = v1.x * v2.x
	v.y = v1.y * v2.y
	return v
end

function vec.divide(v1, v2)
	local v = vec.new()
	v.x = v1.x / v2.x
	v.y = v1.y / v2.y
	return v
end

function vec.angle(v1, v2)
	return math.atan2(v2.y-v1.y, v2.x-v1.x)
end

function vec.dist(v1, v2)
	return ((v2.x-v1.x)^2+(v2.y-v1.y)^2)^0.5
end

function vec:set(x, y)
	x = x or 0
	y = y or 0
	self.x = x
	self.y = y
end

function vec:setAngle(angle)
	local l = self:getLength()
	self.x = math.cos(angle) * l
	self.y = math.sin(angle) * l
end

function vec:getAngle()
	return math.atan2(self.y, self.x)
end


function vec:setLength(length)
	local a = self:getAngle()
	self.x = math.cos(a) * length
	self.y = math.sin(a) * length
end

function vec:getLength()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

function vec:add(v2, dt)
	dt = dt or 1
	if type(v2) == "number" then
		val = v2
		v2 = {x = val, y = val}
	end
	self.x = self.x + v2.x * dt
	self.y = self.y + v2.y * dt
end

function vec:sub(v2, dt)
	dt = dt or 1
	if type(v2) == "number" then
		val = v2
		v2 = {x = val, y = val}
	end
	self.x = self.x - v2.x * dt
	self.y = self.y - v2.y * dt
end

function vec:mult(v2, dt)
	dt = dt or 1
	if type(v2) == "number" then
		val = v2
		v2 = {x = val, y = val}
	end
	self.x = self.x * v2.x * dt
 	self.y = self.y * v2.y * dt
end

function vec:div(v)
	dt = dt or 1
	if type(v2) == "number" then
		val = v2
		v2 = {x = val, y = val}
	end
	self.x = self.x / v2.x
	self.y = self.y / v2.y
end

function vec:limit(v)
	if self:getLength() > v then
		self:setLength(v)
	end
end

function vec:unpack()
	return self.x, self.y
end

function vec.getNormal(v2)
	local l = v2:getLength()
	if l > 0 then
		return vec.new(v2.x / l, v2.y / l)
	else
		return vec.new(0, 0)
	end
end



return vec