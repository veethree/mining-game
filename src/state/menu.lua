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
    if #menu.screen.new.worldName.text < 1 then
        note:new("Please enter a world name!", "danger") 
    else
        local seed = menu.screen.new.seed.text
        -- If no seed is provided, Use the current time
        if #seed < 1 then
            seed = os.time()
        end
        if tonumber(seed) then 
            seed = tonumber(seed) 
        else
            seed = hashcode(seed)
        end

        if seed > maxSeed then
            seed = maxSeed
        end

        state:load("game", {type = "new", worldName = menu.screen.new.worldName.text, seed = tonumber(seed)})
    end
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

local function removeDirectory(dir)
    if fs.getInfo(dir).type == "directory" then
        for _, sub in pairs( fs.getDirectoryItems(dir)) do
            removeDirectory(dir.."/"..sub)
            fs.remove(dir.."/"..sub)
        end
    else
        fs.remove(dir)
    end
    fs.remove(dir)
end

local function delete()
    local selected = false
    local selectedIndex = false
    for i,v in ipairs(menu.screen.load) do
        if v.type == "textbox" then
            if v.selected then
                selected = v
                selectedIndex = i
                break
            end   
        end
    end
    if selected then
        if not menu.deleteConfirmed then
            note:new("Warning: This will delete the world PERMANENTLY. This is your only warning", "danger", 8)
            menu.deleteConfirmed = true
        else
            removeDirectory("worlds/"..selected.text)
            menu.screen.load[selectedIndex] = nil
            note:new("World '"..selected.text.."' deleted.", "success")
        end
    end

end

function menu:load()
    lg.setBackgroundColor(0.1, 0.1, 0.1)
    self.width, self.height = lg.getWidth(), lg.getHeight()
    self.color = {
        fg = {1, 1, 1},
        bg = {0, 0, 0},
        idle = {0.4, 0.4, 0.4},
        danger = {0.8, 0.2, 0.2},
        success = {0.4, 0.9, 0.4}
    }

    self.currentScreen = "main"
    self.screen = {
        main = {
            label.new(NAME, self.color.success, font.large, 0, lg.getHeight() * 0.2, "center"),
            label.new(VERSION, self.color.success, font.regular, 12, 12, "left"),
            button.new("New world", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09, newButton),
            button.new("Load world", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, loadButton),
            button.new("Options", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.7, self.width * 0.4, self.height * 0.09, startButton),
            button.new("Exit", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.8, self.width * 0.4, self.height * 0.09, exitButton),
        },
        new = {
            label.new("New world", self.color.success, font.large, 0, lg.getHeight() * 0.2, "center"),
            worldName = textbox.new("", "World name", self.color.fg, self.color.idle, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09),
            seed = textbox.new("", "Seed", self.color.fg, self.color.idle, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, false, 10),
            button.new("Create world", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.7, self.width * 0.4, self.height * 0.09, createButton),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.8, self.width * 0.4, self.height * 0.09, backButton),
        },
        load = {
            label.new("Load world", self.color.success, font.large, lg.getWidth() * 0.05, lg.getHeight() * 0.2, "left"),
            button.new("Load world", self.color.success, self.color.bg, self.width * 0.05, self.height * 0.6, self.width * 0.25, self.height * 0.09, load),
            button.new("Delete world", self.color.danger, self.color.bg, self.width * 0.05, self.height * 0.7, self.width * 0.25, self.height * 0.09, delete),
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

    self.deleteConfirmed = false



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
        if type(v.mousepressed) == "function" then
            v:mousepressed(x, y, k)
        end
    end
end

return menu