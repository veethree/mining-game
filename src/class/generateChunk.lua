local chunksToGenerate, chunkSize, tileSize, seed = ...

love.math = require("love.math")
love.mouse = require("love.mouse")

local noiseScale = 0.13
local noiseScaleOre = 0.1
local noiseScaleOre2 = 0.01
local noiseScaleBiome = 0.0001

local ground = 1--{0.5, 0.5, 0.5}
local ground2 = {0.51, 0.51, 0.51}
local wallEdge = 1--{0.3, 0.3, 0.3}
local wall = {0, 0, 0}
local coal = 2--{1, 0.5, 0}
local iron = 4--{0, 0.5, 1}
local diamond = 3
local ruby = 5

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
                local tileX = (v.x * chunkSize) + x
                local tileY = (v.y * chunkSize) + y
                local worldX = chunkWorldX + (x * tileSize)
                local worldY = chunkWorldY + (y * tileSize)
                local tile = wall
                local biome = 1
                local noiseBase = love.math.noise(tileX * noiseScale, tileY * noiseScale, tonumber(seed))
                local noiseBiome = love.math.noise(tileX * noiseScaleBiome, tileY * noiseScaleBiome, tonumber(seed) + 300)
                local noiseCoal = love.math.noise(tileX * noiseScaleOre, tileY * noiseScaleOre, tonumber(seed))
                local noiseIron = love.math.noise(tileX * noiseScaleOre, tileY * noiseScaleOre, tonumber(seed), 100)
                local noiseDiamond = love.math.noise(tileX * noiseScaleOre, tileY * noiseScaleOre, tonumber(seed), 200)
                local scale = 0.4
                if noiseBase > scale then
                    tile = ground

                    if love.math.random() < 0.0002 then
                        tile = ruby
                    end

                    if noiseCoal > 0.7 then
                        tile = coal
                    end
                    if noiseIron > 0.76 then
                        tile = iron
                    end
                    if noiseDiamond > 0.8 then
                        tile = diamond
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
                    finalChunk.tiles[#finalChunk.tiles+1] = {x = tile.x, y = tile.y, color = tile.type, biome = tile.biome}
                end
            end
        end

        love.thread.getChannel("worldGen"):push(finalChunk)
    end
end
