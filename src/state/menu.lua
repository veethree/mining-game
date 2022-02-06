local menu = {}

-- Button functions
local function newButton()
    menu.currentScreen = "new"
end

local function loadButton()
    menu.currentScreen = "load"
end

local function backButton()
    menu.currentScreen = "main"
end

local function exitButton()
    love.event.push("quit")
end

local function createButton()
    state:load("game", {type = "new", worldName = menu.screen.new.worldName.text, seed = menu.screen.new.seed.text})
end

local function load()
    local selected = false
    for i,v in ipairs(menu.screen.load) do
        if v.type == "textbox" then
            if v.selected then
                selected = v
                break
            end   
        end
    end
    if selected then
        state:load("game", {type = "load", worldName = selected.text})
    end
end

function menu:load()
    lg.setBackgroundColor(0.1, 0.1, 0.1)
    self.width, self.height = lg.getWidth(), lg.getHeight()
    self.color = {
        fg = {1, 1, 1},
        bg = {0, 0, 0},
        idle = {0.4, 0.4, 0.4},
        danger = {0.8, 0.2, 0.2}
    }

    self.currentScreen = "main"
    self.screen = {
        main = {
            button.new("New world", self.color.fg, self.color.bg, self.width * 0.05, self.height * 0.5, self.width * 0.25, self.height * 0.09, newButton),
            button.new("Load world", self.color.fg, self.color.bg, self.width * 0.05, self.height * 0.6, self.width * 0.25, self.height * 0.09, loadButton),
            button.new("Options", self.color.fg, self.color.bg, self.width * 0.05, self.height * 0.7, self.width * 0.25, self.height * 0.09, startButton),
            button.new("Exit", self.color.fg, self.color.bg, self.width * 0.05, self.height * 0.8, self.width * 0.25, self.height * 0.09, exitButton),
        },
        new = {
            worldName = textbox.new("", "World name", self.color.fg, self.color.idle, self.color.bg, self.width * 0.05, self.height * 0.5, self.width * 0.25, self.height * 0.09),
            seed = textbox.new("", "Seed", self.color.fg, self.color.idle, self.color.bg, self.width * 0.05, self.height * 0.6, self.width * 0.25, self.height * 0.09, tonumber),
            button.new("Create world", self.color.fg, self.color.bg, self.width * 0.05, self.height * 0.7, self.width * 0.25, self.height * 0.09, createButton),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.05, self.height * 0.8, self.width * 0.25, self.height * 0.09, backButton),
        },
        load = {
            button.new("Delete world", self.color.danger, self.color.bg, self.width * 0.05, self.height * 0.6, self.width * 0.25, self.height * 0.09),
            button.new("Load world", self.color.fg, self.color.bg, self.width * 0.05, self.height * 0.7, self.width * 0.25, self.height * 0.09, load),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.05, self.height * 0.8, self.width * 0.25, self.height * 0.09, backButton),
        }
    }

    local y = 0.1
    for i, world in ipairs(fs.getDirectoryItems("worlds")) do
        if fs.getInfo("worlds/"..world).type == "directory" then
            self.screen.load[#self.screen.load+1] = textbox.new(world, world, self.color.fg, self.color.idle, self.color.bg, self.width * 0.35, self.height * y, self.width * 0.5, self.height * 0.09, function() return false end)
            y = y + 0.1
        end
    end




end

function menu:update(dt)
    
end

function menu:draw()
    for i,v in pairs(self.screen[self.currentScreen]) do
        v:draw()
    end
end

function menu:textinput(t)
    for i,v in pairs(self.screen[self.currentScreen]) do
        if type(v.textinput) == "function" then
            v:textinput(t)
        end
    end
end

function menu:keypressed(key)
    for i,v in pairs(self.screen[self.currentScreen]) do
        if type(v.keypressed) == "function" then
            v:keypressed(key)
        end
    end
end

function menu:mousepressed(x, y, k)
    for i,v in pairs(self.screen[self.currentScreen]) do
        v:mousepressed(x, y, k)
    end
end

return menu