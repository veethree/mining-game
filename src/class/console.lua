local console = {}

function setColor(r, g, b, a)
	if type(r) == "table" then
		r, g, b, a = r[1], r[2], r[3], r[4]
	end
	a = a or 255

	love.graphics.setColor(convertColor(r, g, b, a))
end

--==[[ < INTERNAL METHODS > ]]==--

function console:updateTextboxIndicator()
	self.textBox.indicator.x = self.textBox.x + self.margin.x + self.font:getWidth(self.sub(self.textBox.text, 1, self.textBox.indicator.position)) - 2
	if self.textBox.indicator.x > self.textBox.x + self.textBox.width - self.margin.x - 2 then 
		self.textBox.indicator.x = self.textBox.x + self.textBox.width - self.margin.x - 2
	end

	if self.textBox.indicator.position == 0 then
		self.textBox.indicator.x = self.textBox.x + self.margin.x
	elseif self.textBox.indicator.position == 1 then
		self.textBox.indicator.x = self.textBox.x + self.margin.x + self.font:getWidth(self.sub(self.textBox.text, 1, 1)) -2
	end

	self.textBox.indicator.t = math.pi / 2
end

function console:positionTextboxText()
	if self.font:getWidth(self.sub(self.textBox.text, 1, self.textBox.indicator.position)) >= self.textBox.width - (self.margin.x * 2) then
		self.textBox.textX = (self.textBox.x + self.textBox.width - self.margin.x) - self.font:getWidth(self.sub(self.textBox.text, 1, self.textBox.indicator.position)) 
	else
		self.textBox.textX = self.textBox.x + self.margin.x
	end
end

function console:clearTextBox()
	self.textBox.history[#self.textBox.history + 1] = self.textBox.text
	self.textBox.historyPosition = #self.textBox.history
	self.textBox.text = ""
	self:updateTextboxIndicator()
	self:positionTextboxText()
end

function console:lua(text)
	local status, err = pcall(loadstring(text))
	err = err or false
	if err then
		self:print("LUA: "..tostring(err))
	end
end

function console:clearHistory()
	self.history.text = {}
	self.history.position = 1
end

local function wrapString(text, maxWidth, font)
	maxWidth = maxWidth or love.graphics.getWidth()
	font = font or love.graphics.getFont()

	local words = {}
	local str = ""
	local lineWidth = 0
	local lineCount = 1
	text:gsub("([^ ]+)", function(c) words[#words+1] = c.." " end)

	for i,v in ipairs(words) do
		local n = lineWidth + font:getWidth(v)
		if n > maxWidth then
			str = str.."\n"
			lineCount = lineCount + 1
			lineWidth = 0
		end
		str = str..v
		lineWidth = lineWidth + font:getWidth(v)
	end
	return str, lineCount, (font:getAscent() - font:getDescent()) * lineCount
end
	
--STRING FUNCTIONS	
function console.getCharBytes(string, char)
	char = char or 1
	local b = string.byte(string, char)
	local bytes = 1
	if b > 0 and b <= 127 then
      bytes = 1
   elseif b >= 194 and b <= 223 then
      bytes = 2
   elseif b >= 224 and b <= 239 then
      bytes = 3
   elseif b >= 240 and b <= 244 then
      bytes = 4
   end
	return bytes
end

function console.len(str)
	local pos = 1
	local len = 0
	while pos <= #str do
		len = len + 1
		pos = pos + console.getCharBytes(str, pos)
	end
	return len
end

function console.sub(str, s, e)
	s = s or 1
	e = e or console.len(str)

	if s < 1 then s = 1 end
	if e < 1 then e = console.len(str) + e + 1 end
	if e > console.len(str) then e = console.len(str) end

	if s > e then return "" end

	local sByte = 0
	local eByte = 1

	local pos = 1
	local i = 0
	while pos <= #str do
		i = i + 1
		if i == s then
			sByte = pos
		end
		pos = pos + console.getCharBytes(str, pos)
		if i == e then
			eByte = pos - 1
			break
		end
	end

	return string.sub(str, sByte, eByte)
end

function console.setAlpha(a)
	local r, g, b, _a = love.graphics.getColor()
	setColor(r, g, b, a)
end

--==[[ < PUBLIC METHODS > ]]==--

--CALLBACKS
function console:init(x, y, width, height, visible, font)
	--Outside variables
	self.userKeyRepeat = love.keyboard.hasKeyRepeat()

	--Defaults
	x = x or 0
	y = y or 0
	width = width or love.graphics.getWidth()
	height = height or love.graphics.getHeight()
	visible = visible or true
	font = font or love.graphics.newFont(16)
	love.keyboard.setKeyRepeat(visible)

	--Options
	self.x = x
	self.y = y
	self.margin = {
		x = 8,
		y = 4
	}
	self.width = width
	self.height = height
	self.font = font
	self.visible = visible

	--Elements
	self.textBox = {
		x = self.x,
		y = self.y + self.height - (self.font:getAscent() - font:getDescent() + (self.margin.y * 2)),
		textX = self.margin.x,
		width = self.width,
		height = (self.font:getAscent() - font:getDescent()) + (self.margin.y * 2),
		text = "",
		indicator = {
			x = self.x + self.margin.x,
			position = 0,
			char = "|",
			t = 0, 
			alpha = 1,
			flashRate = 6
		},
		color = {
			box = {0, 0, 0, 200},
			text = {255, 255, 255, 255}
		},
		history = {},
		historyPosition = 1,
		mode = "input"
	}

	self.history = {
		x = self.x,
		y = self.y,
		yOffset = 0,
		width = self.width,
		height = self.height - self.textBox.height,
		totalTextHeight = 0,
		scrollSpeed = 32,
		color = {
			box = {0, 0, 0, 150},
			text = {200, 200, 200, 255}
		},
		text = {},
		maxHistory = 64
	}
end

function console:resize(width, height)
	self.width = width
	self.height = height
	self.textBox.width = width
	self.textBox.y = height - self.textBox.height
	self.history.width = width
	self.history.height = height - self.textBox.height
	for i,v in ipairs(self.history.text) do
		local text, lines, height = wrapString(v.textRaw, width, self.font)
		v.text = text
		v.lines = lines
		v.height = height
	end
end

function console:update(dt)
	if self.visible then
		--Textbox Indicator
		self.textBox.indicator.t = self.textBox.indicator.t + self.textBox.indicator.flashRate * dt
		if self.textBox.indicator.t > math.pi then self.textBox.indicator.t = 0 end
	end
end

function console:draw()
	if self.visible then
		--Textbox
		console.setAlpha(1)
		love.graphics.setScissor(self.textBox.x, self.textBox.y, self.textBox.width, self.textBox.height)
		love.graphics.setFont(self.font)
		setColor(self.textBox.color.box)
		love.graphics.rectangle("fill", self.textBox.x, self.textBox.y, self.textBox.width, self.textBox.height)
		setColor(self.textBox.color.text)
		love.graphics.print(self.textBox.text, self.textBox.textX, self.textBox.y + self.margin.y)

		--textBox indicator
		lg.setColor(1, 1, 1, 1)
		console.setAlpha(math.sin(self.textBox.indicator.t))
		love.graphics.print(self.textBox.indicator.char, self.textBox.indicator.x, self.textBox.y + self.margin.y)
		love.graphics.setScissor()

		--History
		console.setAlpha(1)
		love.graphics.setScissor(self.history.x, self.history.y, self.history.width, self.history.height)
		setColor(self.history.color.box)
		love.graphics.rectangle("fill", self.history.x, self.history.y, self.history.width, self.history.height)
		local y = (self.history.y + self.history.height - self.margin.y) + self.history.yOffset
		for i=#self.history.text, 1, -1 do
			local v = self.history.text[i]
			y = y - v.height
			setColor(v.color)
			love.graphics.print(v.text, self.history.x + self.margin.x, y)
		end
		love.graphics.setScissor()
	end
end

function console:textinput(t)
	if self.visible then
		if self.textBox.indicator.position == self.len(self.textBox.text) then
			self.textBox.text = self.textBox.text..t
		else
			if self.textBox.indicator.position > 0 then
				local b = self.sub(self.textBox.text, 1, self.textBox.indicator.position)
				local e = self.sub(self.textBox.text, self.textBox.indicator.position + 1)
				self.textBox.text = b..t..e
			else
				self.textBox.text = t..self.textBox.text
			end
		end
		self.textBox.indicator.position = self.textBox.indicator.position + 1
		if self.textBox.indicator.position >= self.len(self.textBox.text) then self.textBox.indicator.position = self.len(self.textBox.text) end
		self.textBox.mode = "input"
		self:updateTextboxIndicator()
		self:positionTextboxText()
	end
end

function console:keypressed(key)
	if self.visible then
		if key == "backspace" then
			if #self.textBox.text > 0 then
				if self.textBox.indicator.position == self.len(self.textBox.text) then
					self.textBox.text = console.sub(self.textBox.text, 1, -2)
				else
					if self.textBox.indicator.position > 0 then
						if self.textBox.indicator.position > 1 then
							local b = self.sub(self.textBox.text, 1, self.textBox.indicator.position - 1)
							local e = self.sub(self.textBox.text, self.textBox.indicator.position + 1)
							self.textBox.text = b..e
						else
							self.textBox.text = self.sub(self.textBox.text, 2)
						end
					end
				end
				self.textBox.indicator.position = self.textBox.indicator.position - 1
				if self.textBox.indicator.position < 0 then self.textBox.indicator.position = 0 end
				self.textBox.mode = "input"
				self:updateTextboxIndicator()
				self:positionTextboxText()
			end
		elseif key == "up" then
			if #self.textBox.history > 0 then
				if self.textBox.mode == "history" then
					self.textBox.historyPosition = self.textBox.historyPosition - 1
					if self.textBox.historyPosition < 1 then self.textBox.historyPosition = 1 end
				else
					if #self.textBox.text > 0 then
						self.textBox.history[#self.textBox.history + 1] = self.textBox.text
					end
				end
				self.textBox.text = self.textBox.history[self.textBox.historyPosition]
				self:updateTextboxIndicator()
				self:positionTextboxText()
				self.textBox.mode = "history"
			end
		elseif key == "down" then
			if self.textBox.mode == "history" then
				self.textBox.historyPosition = self.textBox.historyPosition + 1
				if self.textBox.historyPosition > #self.textBox.history then self.textBox.historyPosition = #self.textBox.history end
				self.textBox.text = self.textBox.history[self.textBox.historyPosition]
				self:updateTextboxIndicator()
				self:positionTextboxText()
				self.textBox.mode = "history"
			end
		elseif key == "left" then
			self.textBox.indicator.position = self.textBox.indicator.position - 1
			if self.textBox.indicator.position < 0 then self.textBox.indicator.position = 0 end
			self:updateTextboxIndicator()
			console:positionTextboxText()
		elseif key == "right" then
			self.textBox.indicator.position = self.textBox.indicator.position + 1
			if self.textBox.indicator.position >= self.len(self.textBox.text) then self.textBox.indicator.position = self.len(self.textBox.text) end
			self:updateTextboxIndicator()
			console:positionTextboxText()
		elseif key == "return" then
			console:lua(self.textBox.text)
			self:clearTextBox()
		elseif key == "pageup" then
			self.history.yOffset = self.history.yOffset + self.history.scrollSpeed
			if self.history.yOffset > self.history.totalTextHeight then
				self.history.yOffset = self.history.totalTextHeight
			end
		elseif key == "pagedown" then
			self.history.yOffset = self.history.yOffset - self.history.scrollSpeed
			if self.history.yOffset < 0 then self.history.yOffset = 0 end
		elseif key == "v" then
			if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
				local pastedText = love.system.getClipboardText()
				if #pastedText > 0 then
					if self.textBox.indicator.position == self.len(self.textBox.text) then
						self.textBox.text = self.textBox.text..pastedText
					else
						if self.textBox.indicator.position > 0 then
							local b = self.sub(self.textBox.text, 1, self.textBox.indicator.position)
							local e = self.sub(self.textBox.text, self.textBox.indicator.position + 1)
							self.textBox.text = b..pastedText..e
						else
							self.textBox.text = pastedText..self.textBox.text
						end
					end
					self.textBox.indicator.position = self.textBox.indicator.position + self.len(pastedText)
					self:updateTextboxIndicator()
					self:positionTextboxText()
				end
			end
		elseif key == "c" then
			if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
				if #self.textBox.text > 0 then
					love.system.setClipboardText(self.textBox.text)
				end
			end
		end
	end
end

function console:wheelmoved(sx, sy)
	local x, y = love.mouse.getPosition()
	if sy > 0 then
		if x > self.history.x and x < self.history.x + self.history.width and y > self.history.y and y < self.history.y + self.history.height then
			self.history.yOffset = self.history.yOffset + self.history.scrollSpeed
			if self.history.yOffset > (self.history.totalTextHeight - self.history.height + (self.margin.y * 2)) then
				self.history.yOffset = self.history.totalTextHeight - self.history.height + (self.margin.y * 2)
			end
		end
	elseif sy < 0 then
		if x > self.history.x and x < self.history.x + self.history.width and y > self.history.y and y < self.history.y + self.history.height then
			self.history.yOffset = self.history.yOffset - self.history.scrollSpeed
			if self.history.yOffset < 0 then self.history.yOffset = 0 end
		end
	end
end

function console:print(text, color)
	if text then
		text = tostring(text)
		color = color or self.history.color.text
		local wrappedText, lines, height = wrapString(text, self.history.width, self.font)
		self.history.text[#self.history.text + 1] = {
			textRaw = text,
			text = wrappedText,
			lines = lines,
			height = height,
			color = color
		}
		self.history.totalTextHeight = self.history.totalTextHeight + height
		self.history.yOffset = 0
		if #self.history.text > self.history.maxHistory then
			self.history.totalTextHeight = self.history.totalTextHeight - self.history.text[1].height
			table.remove(self.history.text, 1)
		end
	end
end

--Setters/Getters
function console:setVisible(visible)
	self.visible = visible
	if visible then
		love.keyboard.setKeyRepeat(true)
	else
		love.keyboard.setKeyRepeat(self.userKeyRepeat)
	end
end

function console:getVisible()
	return self.visible
end

function console:setFont(font)
	if font then
		self.font = font
		self.textBox.height = (font:getAscent() - font:getDescent()) + (self.margin.y * 2)
		self.textBox.y = self.y + self.height - self.textBox.height
	end
end

return console