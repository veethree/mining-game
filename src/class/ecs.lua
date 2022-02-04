-- IMPORTANT: This module requires spatial.lua to function. (https://github.com/veethree/spatial)
-- spatial.lua should be in the same folder as ecs.lua.

-- ecs.lua: A minimal entity component system module for löve
-- Definitions: 
--      Entity: A lua file that returns a table that should contain all data pretaining to the specific entity.
--      Component: A component, As far as this module is concerned, Is any data in the entities table.
--                 There are a few special components
--                 _REMOVE: If an entity has this component, Set to a truthy value, It will be removed in the next update.
--      System: A lua file that returns a table that should contain any data & methods pretaining to the specified system.
--              A system should have the following methods:
--              process: This is the only strictly required method, It is the main method of the system, That will be called for every
--                       entity currently in the world with the entity table as an argument. Use this method to process each entity
--                       however you see fit.
--              filter: This method is optional, But it can be used to filter which entities are affected by the system. It's called with
--                      the entity table as an argument, And if it returns a truthy value, The entity will be processed.
-- 
-- ecs.lua stores it's entities in a spatial database provided by spatial.lua. To give the user as much control as possible, The user 
-- must tell ecs.lua which entities to process at any given point via queries to the spatial database.


--Shorthands
local fs = love.filesystem
local f = string.format
local insert = table.insert


local ecs = {path = ...}
local ecs_meta = {__index = ecs}
local directory = ecs.path:gsub("%.", "/"):gsub("ecs", "")

-- Checking if spatial.lua is present and loading it/throwing error
local spatial
if fs.getInfo(directory.."/spatial.lua") then
    spatial = require(directory.."/spatial")
else
    error("spatial.lua not found!")
end

function ecs.new()
    return setmetatable({
        system = {},
        entity = spatial.new(config.graphics.tileSize)
    }, ecs_meta)
end

-- Creates a new system
function ecs:newSystem(path)
    assert(fs.getInfo(path), f("File '%s' doesn't exist!", path))
    insert(self.system, fs.load(path)())
end

function ecs:loadSystemFromFolder(path)
    assert(fs.getInfo(path), f("Folder '%s' doesn't exist!", path))
    assert(fs.getInfo(path).type == "directory", f("'%s' is not a folder!", path))

    local files = fs.getDirectoryItems(path)
    for _,file in ipairs(files) do
        self:newSystem(path.."/"..file)
    end
end

-- The x and y in this function are used to enter the entity into the spatial database,
function ecs:newEntity(path, x, y, data)
    assert(fs.getInfo(path), f("File '%s' doesn't exist!", path))
    local entity = self.entity:insert(x, y, fs.load(path)())
    if type(entity.load) == "function" then
        entity:load(data, self)
    end
    return entity
end

function ecs:removeEntity(entity)
    self.entity:remove(entity)
end

function ecs:queryRect(x, y, w, h, filter)
    return self.entity:queryRect(x, y, w, h, filter)
end

function ecs:query(filter)
    return self.entity:query(filter)
end

-- Updating the world
function ecs:update(entity_list, dt)
    dt = dt or love.timer.getDelta()
    for _, system in pairs(self.system) do
        for _, entity in pairs(entity_list) do
            -- Processing entities
            if system.filter and system.filter(entity) then
                system.process(entity, dt)
            end
        end
    end

    -- Removing _REMOVE entities
    for i,v in ipairs(self:query()) do
        if v._REMOVE then
            self:removeEntity(v)
        end
    end
end

return ecs