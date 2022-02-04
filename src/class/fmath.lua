--Various vaguely useful math functions

local fmath = {}

function fmath.normal(val, min, max)
	return (val - min) / (max - min)
end

function fmath.lerp(val, min, max)
	return (max - min) * val + min
end

function fmath.clamp(val, min, max)
	return math.max(min, math.min(val, max))
end

function fmath.distance(x1, y1, x2, y2)
	if type(x1) == "table" and type(y1) == "table" then
		if x1.x and x1.y and y1.x and y1.y then
			local x, y, xx, yy = x1.x, x1.y, y1.x, y1.y
			x1 = x
			y1 = y
			x2 = xx
			y2 = yy
		else
			return false
		end
	end
	return ((x2-x1)^2+(y2-y1)^2)^0.5
end

function fmath.pointInRect(px, py, rx, ry, rw, rh)
	if px > rx and px < rx + rw and py > ry and py < ry + rh then
		return true
	else return false end
end

function fmath.rect(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

function fmath.angle(x1, y1, x2, y2)
	return math.atan2(y2-y1, x2-x1)
end

function fmath.randomBool()
	if math.random() >= 0.5 then return true else return false end
end

return fmath