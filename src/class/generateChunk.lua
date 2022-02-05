local chunksToGenerate, chunkSize, tileSize, seed = ...

love.math = require("love.math")
love.mouse = require("love.mouse")

local noiseScale = 0.13

local ground = 1--{0.5, 0.5, 0.5}

local coal = 2--{1, 0.5, 0}
local coalNoiseScale = 0.1
local coalThreshold = 0.74

local iron = 3--{0, 0.5, 1}
local ironNoiseScale =  0.15
local ironThreshold = 0.78

local gold = 4
local goldNoiseScale = 0.09
local goldthreshold = 0.8

local uranium = 5
local uraniumNoiseScale = 0.2
local uraniumThreshold = 0.85

local diamond = 6
local diamondNoiseScale = 0.2
local diamondThreshold = 0.81

local ruby = 7
local rubyNoiseScale = 0.1
local rubyThreshold = 0.81

local tanzenite = 8
local tanzeniteNoiseScale = 0.01
local tanzeniteThreshold = 0.7

local tiles = {}


if type(chunksToGenerate) == "table" then
    for i,v in ipairs(chunksToGenerate) do
        local finalChunk = {
            x = v.x,
            y = v.y,
            tiles = {}
        }
        local chunkWorldX = v.x * chunkSize * tileSize
        local chunkWorldY = v.y * chunkSize * tileSize

        local chunk = {}
        for y=1, chunkSize do
            chunk[y] = {}
            for x=1, chunkSize do
                -- Coordinates
                local tileX = (v.x * chunkSize) + x
                local tileY = (v.y * chunkSize) + y
                local worldX = chunkWorldX + (x * tileSize)
                local worldY = chunkWorldY + (y * tileSize)

                -- Tile setup
                local tile = wall
                local biome = 1

                -- Noises
                local noiseBase = love.math.noise(tileX * noiseScale, tileY * noiseScale, tonumber(seed))
                local noiseCoal = love.math.noise(tileX * coalNoiseScale, tileY * coalNoiseScale, tonumber(seed))
                local noiseIron = love.math.noise(tileX * ironNoiseScale, tileY * ironNoiseScale, tonumber(seed + 100))
                local noiseGold = love.math.noise(tileX * goldNoiseScale, tileY * goldNoiseScale, tonumber(seed + 200))
                local noiseUranium = love.math.noise(tileX * uraniumNoiseScale, tileY * uraniumNoiseScale, tonumber(seed + 300))
                local noiseDiamond = love.math.noise(tileX * diamondNoiseScale, tileY * diamondNoiseScale, tonumber(seed + 400))
                local noiseRuby = love.math.noise(tileX * rubyNoiseScale, tileY * rubyNoiseScale, tonumber(seed + 500))
                local noiseTanzenite = love.math.noise(tileX * tanzeniteNoiseScale, tileY * tanzeniteNoiseScale, tonumber(seed + 600))


                -- Tile type deciding
                local scale = 0.4
                if noiseBase > scale then
                    tile = ground

                    -- COAL
                    if noiseCoal > coalThreshold then
                        tile = coal 
                    end

                    -- IRON
                    if noiseIron > ironThreshold then
                        tile = iron 
                    end

                    -- GOLD
                    if noiseGold > goldthreshold then
                        tile = gold 
                    end

                    -- URANIUM
                    if noiseUranium > uraniumThreshold then
                        tile = uranium
                    end

                    -- DIAMOND
                    if noiseDiamond > diamondThreshold then
                        tile = diamond
                    end

                    -- RUBY
                    if noiseRuby > rubyThreshold then
                        tile = ruby
                    end

                    -- TANZENITE
                    if noiseTanzenite > tanzeniteThreshold then
                        tile = tanzenite
                    end


                end

                chunk[y][x] = {type = tile, x = worldX, y = worldY, biome = biome}
            end
        end

        -- Creating wall edges
        for y=1, #chunk do
            for x=1, #chunk[1] do
                local tile = chunk[y][x]

                -- Gathering neighbours
                local adjescentCoord = {
                    {x = x - 1, y = y},
                    {x = x + 1, y = y},
                    {x = x, y = y - 1},
                    {x = x, y = y + 1},
                }
                local adjescent = {}
                for i,v in ipairs(adjescentCoord) do
                    if chunk[v.y] then
                        if chunk[v.y][v.x] then
                            adjescent[#adjescent+1] = chunk[v.y][v.x]
                        end
                    end 
                end
                
                if tile.type == wall then
                    local isEdge = false
                    for i,v in ipairs(adjescent) do
                        if v.type == ground then
                            --isEdge = true
                        end
                    end
                    if isEdge then
                        tile.type = wallEdge
                    end
                end


            end
        end

        for y=1, #chunk do
            for x=1, #chunk[1] do
                local tile = chunk[y][x]
                if tile.type ~= wall then
                    finalChunk.tiles[#finalChunk.tiles+1] = {x = tile.x, y = tile.y, type = tile.type, biome = tile.biome}
                end
            end
        end

        love.thread.getChannel("worldGen"):push(finalChunk)
    end
end
