NAME = "Untitled"
VERSION = 0.1
 
-- GLOBALS
lg = love.graphics
fs = love.filesystem
kb = love.keyboard
lt = love.thread
random = math.random
noise = love.math.noise
sin = math.sin
cos = math.cos
f = string.format
floor = math.floor


function love.load()
    seed = os.time() + love.mouse.getX() * love.mouse.getY()
    -- Loaidng classes
    require("src.class.util")
    require_folder("src/class")

    exString.import()

    --Global keypress events love.system.openURL("file://"..love.filesystem.getSaveDirectory())
    keybind:new("keypressed", {"escape"}, love.event.push, "quit")
    keybind:new("keypressed", {"escape","lshift"}, love.system.openURL, "file://"..love.filesystem.getSaveDirectory())

    -- Defining states
    state:define_state("src/state/game.lua", "game")

    --Config
    default_config = {
        window = {
            width = 1024,
            height = 576,
            fullscreen = false,
            title = NAME.." ["..VERSION.."]"
        },
        graphics = {
            useLight = true,
            lightDistance = 400,
            tileSize = 32,
            assetSize = 16
        },
        debug = {
            enabled = true,
            text_color = {255, 144, 79},
            showChunkBorders = false
        }
    }

    config = default_config
    if fs.getInfo("config.lua") then
        --config = ttf.load("config.lua")
    else
        --save_config()
    end

    -- Creating window
    love.window.setMode(config.window.width, config.window.height, {fullscreen=config.window.fullscreen})
    love.window.setTitle(config.window.title)

    lg.setDefaultFilter("nearest", "nearest")
    lg.setLineStyle("rough")

    --Scaling
    scale_x = lg.getWidth() * 0.001
    scale_y = lg.getHeight() * 0.001

    --Loading fonts
    font = {
        regular = lg.newFont("src/font/monogram.ttf", 42 * scale_x)
    }

    load_assets()

    -- Loading tileset

    tileAtlas, tiles = loadAtlas("src/assets/tileset.png", 16, 16, 0)

    state:load("game")


end

function load_assets()
    -- Auto loads assets
    -- The assets are stored in the global 'assets' table, Sorted by file type
    -- ex: assets.mp3.mainMusic / assets.png/texture
    -- Filenames that start with a _ are ignored
    -- ex: "_song.mp3"
    local img = {"png", "jpg"}
    local assets_folder = "src/assets"
    assets = {}
    local files = fs.getDirectoryItems(assets_folder)
    for _,file in ipairs(files) do
        local name, ext = get_file_name(file), get_file_type(file)
        if not name:startsWith("_") then
            if not assets[ext] then assets[ext] = {} end
            local ass
            -- IMAGE
            if hasValue(img, ext) then
                ass = lg.newImage(f("%s/%s", assets_folder, file))
            end

            assets[ext][name] = ass
        end
    end
end

function save_config()
    ttf.save(config, "config.lua")
end

function clear_config()
    fs.remove("config.lua")
end

--The following are callback functions
function love.update(dt)
    keybind:trigger("keydown")
    state:update(dt)

end

function love.draw()
    lg.setColor(1, 1, 1, 1)
    state:draw()

    lg.setColor(1, 0, 1)
    lg.print(love.timer.getFPS(), 12, 12)
end

function love.keypressed(key)
    keybind:keypressed(key)
    keybind:trigger("keypressed", key)
    state:keypressed(key)


    if key == "l" then
        config.graphics.useLight = not config.graphics.useLight
    elseif key == "b" then
        config.debug.showChunkBorders = not config.debug.showChunkBorders
    end
end

function love.textinput(t)
    state:textinput(t)
end

function love.keyreleased(key)
    keybind:trigger("keyreleased", key)
    keybind:keyreleased(key)
    state:keyreleased(key)
end

function love.mousepressed(x, y, key)
    state:mousepressed(x, y, key)
end

function love.mousereleased(x, y, key)
    state:mousereleased(x, y, key)
end

function love.wheelmoved(x, y)
    state:wheelmoved(x, y)
end

function love.quit()
    state:quit()
end
