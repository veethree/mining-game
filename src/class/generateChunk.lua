local chunksToGenerate, chunkSize, tileSize, seed = ...

seed = tonumber(seed)

love.math = require("love.math")
love.mouse = require("love.mouse")

local noise = love.math.noise

local noiseScale = 0.6

-- Base shape as well
local ground = 1--{0.5, 0.5, 0.5}

-- Determines the base shape of the caves
function caveNoise(x, y, scale)
    local scaleBase = 0.09 * scale
    local scaleDetail = 0.3 * scale
    local thresh = 0.45
    return noise(x * scaleBase, y * scaleBase, seed) * 0.7 + noise(x * scaleDetail, y * scaleDetail, seed) * 0.3 > thresh and true or false
end

local coal = 2--{1, 0.5, 0}

function coalNoise(x, y, scale)
    local scaleBase = 0.04 * scale
    local scaleDetail = 0.15 * scale
    local thresh = 0.65
    return noise(x * scaleBase, y * scaleBase, seed + 100) * 0.3 + noise(x * scaleDetail, y * scaleDetail, seed + 100) * 0.7 > thresh and true or false
end

local iron = 3--{0, 0.5, 1}

function ironNoise(x, y, scale)
    local scaleBase = 0.02 * scale
    local scaleDetail = 0.3 * scale
    local thresh = 0.7
    return noise(x * scaleBase, y * scaleBase, seed + 200) * 0.3 + noise(x * scaleDetail, y * scaleDetail, seed + 200) * 0.7 > thresh and true or false
end

local gold = 4
function goldNoise(x, y, scale)
    local scaleBase = 0.1 * scale
    local scaleDetail = 0.6 * scale
    local thresh = 0.8
    return noise(x * scaleBase, y * scaleBase, seed + 300) * 0.4 + noise(x * scaleDetail, y * scaleDetail, seed + 300) * 0.7 > thresh and true or false
end

local uranium = 5
function uraniumNoise(x, y, scale)
    local scaleBase = 0.2 * scale
    local scaleDetail = 0.6 * scale
    local thresh = 0.8
    return noise(x * scaleBase, y * scaleBase, seed + 400) * 0.4 + noise(x * scaleDetail, y * scaleDetail, seed + 400) * 0.7 > thresh and true or false
end

local diamond = 6
function diamondNoise(x, y, scale)
    local scaleBase = 0.04 * scale
    local scaleDetail = 0.06 * scale
    local thresh = 0.88
    return noise(x * scaleBase, y * scaleBase, seed + 500) * 0.5 + noise(x * scaleDetail, y * scaleDetail, seed + 500) * 0.7 > thresh and true or false
end

local ruby = 7
function rubyNoise(x, y, scale)
    local scaleBase = 0.09 * scale
    local scaleDetail = 0.18 * scale
    local thresh = 0.91
    return noise(x * scaleBase, y * scaleBase, seed + 600) * 0.5 + noise(x * scaleDetail, y * scaleDetail, seed + 600) * 0.7 > thresh and true or false
end

local tanzenite = 8
function tanzeniteNoise(x, y, scale)
    local scaleBase = 0.09 * scale
    local scaleDetail = 0.18 * scale
    local thresh = 0.91
    return noise(x * scaleBase, y * scaleBase, seed + 700) * 0.5 + noise(x * scaleDetail, y * scaleDetail, seed + 700) * 0.7 > thresh and true or false
end

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

                -- Tile type deciding
                if caveNoise(tileX, tileY, noiseScale) then
                    tile = ground

                    -- Coalies
                    if coalNoise(tileX, tileY, noiseScale) then
                        tile = coal
                    end
                    -- ironistas
                    if ironNoise(tileX, tileY, noiseScale) then
                        tile = iron
                    end
                    -- goldielocsk
                    if goldNoise(tileX, tileY, noiseScale) then
                        tile = gold
                    end
                    -- hulstuff
                    if uraniumNoise(tileX, tileY, noiseScale) then
                        tile = uranium
                    end
                    -- These are forever
                    if diamondNoise(tileX, tileY, noiseScale) then
                        tile = diamond
                    end
                    -- Blood diamodns
                    if rubyNoise(tileX, tileY, noiseScale) then
                        tile = ruby
                    end
                    -- The rare shit
                    if tanzeniteNoise(tileX, tileY, noiseScale) then
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
