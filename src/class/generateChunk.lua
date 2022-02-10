local chunksToGenerate, chunkSize, tileSize, seed = ...

-- Tonumbering the seed in case it comes in as a string
seed = tonumber(seed)

-- Importing some löve modules
love.math = require("love.math")
love.mouse = require("love.mouse")

-- Shorthands cause i'm lazy
local fs = love.filesystem
local noise = love.math.noise

local noiseScale = 0.6 -- Global noise scale

-- Loading biome files
local biomes = {}
for _, file in ipairs(fs.getDirectoryItems("src/biome")) do
    biomes[#biomes+1] = fs.load("src/biome/"..file)()
end

-- A fractal noise function for more interesting noise
function fractalNoise(x, y, seed, scale, iterations, ampScale, freqScale)
    -- Normal function
    local function normal(value, min, max)
        return (value - min) / (max - min)
    end
    iterations = iterations or 5
    ampScale = ampScale or 0.6
    freqScale = freqScale or 2
    local totalAmp = 0
    local maxValue = 0
    local amp = 1
    local frequency = scale
    local value = 0

    for i=1, iterations do
        value = value + noise(x * frequency, y * frequency, seed ) * amp
        if value > maxValue then
            maxValue = value
        end
        totalAmp = totalAmp + amp
        amp = amp * ampScale
        frequency = frequency * freqScale 
    end

    value = value / totalAmp

    return normal(value, 0, 1)
end

-- Determines the biome, at x & y
local biomeCount = #biomes
function biomeNoise(x, y, scale)
    local scaleBase = 0.1 * scale
    local scaleDetail = 0.09 * scale
    return math.floor((noise(x * scaleBase, y * scaleBase, seed + 100) * 0.8 + noise(x * scaleDetail, y * scaleDetail, seed + 100) * 0.2) * biomeCount + 1)
end

-- A noise function that returs a boolean
function generateNoise(x, y, scaleBase, scaleDetail, thresh, ratio1, ratio2, seedOffset)
    scaleBase = scaleBase * noiseScale
    scaleDetail = scaleDetail * noiseScale
    return noise(x * scaleBase, y * scaleBase, seed + seedOffset) * ratio1 + noise(x * scaleDetail, y * scaleDetail, seed + seedOffset) * ratio2 > thresh and true or false
end

-- Tile definitions. 
local wall = 1
local ground = 2
local coal = 3
local iron = 4
local gold = 5
local uranium = 6
local diamond = 7
local ruby = 8
local tanzenite = 9

-- Generating the requested chunks
if type(chunksToGenerate) == "table" then
    for i,v in ipairs(chunksToGenerate) do
        local finalChunk = {
            x = v.x,
            y = v.y,
            tiles = {}
        }
        -- the world coordinates of the chunk
        local chunkWorldX = v.x * chunkSize * tileSize
        local chunkWorldY = v.y * chunkSize * tileSize

        local chunk = {}
        local biome = 1--biomeNoise(v.x, v.y, noiseScale)
        for y=1, chunkSize do
            chunk[y] = {}
            for x=1, chunkSize do
                -- Grid coordinates for the tile
                local tileX = (v.x * chunkSize) + x
                local tileY = (v.y * chunkSize) + y
                -- World coordinates for the tile
                local worldX = chunkWorldX + (x * tileSize)
                local worldY = chunkWorldY + (y * tileSize)

                -- Tile setup
                local tile = wall

                -- Tile type deciding
                local tileBiome = biomes[biome]
                    
                -- "sway" is an offset, based on noise, Used to generate slightly different terrain at different coordinates
                local sway = -1 + (noise(tileY * 0.01, tileX * 0.01, seed) * 2)
                local swayAmount = 0.05
                if generateNoise(tileX, tileY, tileBiome.caveScaleBase, tileBiome.caveScaleDetail, tileBiome.caveThresh + (swayAmount * sway), tileBiome.caveRatio1, tileBiome.caveRatio2, 0) then
                    tile = ground

                    for i, ore in ipairs(tileBiome.ores) do
                        if generateNoise(tileX, tileY, ore.scaleBase, ore.scaleDetail, ore.thresh, ore.ratio1, ore.ratio2, ore.seedOffset) then
                            local probability = ore.spawnProbability + (love.math.random() * (1 - ore.spawnProbability))
                            if probability >= 1 - ore.spawnProbability then
                                tile = i + 2
                            end
                        end
                    end
                end

                chunk[y][x] = {type = tile, x = worldX, y = worldY, biome = biome}
            end
        end

        for y=1, #chunk do
            for x=1, #chunk[1] do
                local tile = chunk[y][x]
                finalChunk.tiles[#finalChunk.tiles+1] = {x = tile.x, y = tile.y, type = tile.type, biome = tile.biome}
            end
        end

        love.thread.getChannel("worldGen"):push(finalChunk)
    end
end
