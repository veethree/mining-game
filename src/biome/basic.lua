return {
    name = "Basic",
    -- Shape
    caveScaleBase = 0.08,
    caveScaleDetail = 0.33,
    caveThresh = 0.47,
    caveRatio1 = 0.8,
    caveRatio2 = 0.2,

    ores = {
        {
            -- Coal
            type = "Coal",
            scaleBase = 0.07,
            scaleDetail = 0.2,
            thresh = 0.65,
            ratio1 = 0.4,
            ratio2 = 0.6,
            spawnProbability = 0.8,
            seedOffset = 100
        },
        {
            -- Iron
            type = "Iron",
            scaleBase = 0.01,
            scaleDetail = 0.75,
            thresh = 0.7,
            ratio1 = 0.4,
            ratio2 = 0.6,
            spawnProbability = 1,
            seedOffset = 200
        },
        {
            -- Gold
            type = "Gold",
            scaleBase = 0.4,
            scaleDetail = 0.07,
            thresh = 0.699,
            ratio1 = 0.3,
            ratio2 = 0.7,
            spawnProbability = 0.3,
            seedOffset = 250
        },
        {
            -- Uranium
            type = "Uranium",
            scaleBase = 0.02,
            scaleDetail = 0.9,
            thresh = 0.67,
            ratio1 = 0.8,
            ratio2 = 0.2,
            spawnProbability = 0.05,
            seedOffset = 300
        },
        {
            -- Diamond
            type = "Diamond",
            scaleBase = 0.05,
            scaleDetail = 0.004,
            thresh = 0.74,
            ratio1 = 0.7,
            ratio2 = 0.3,
            spawnProbability = 0.2,
            seedOffset = 500
        },
        {
            -- Ruby
            type = "Ruby",
            scaleBase = 0.05,
            scaleDetail = 0.004,
            thresh = 0.74,
            ratio1 = 0.7,
            ratio2 = 0.3,
            spawnProbability = 0.2,
            seedOffset = 400
        },
        {
            -- Tanzenite
            type = "Tanzenite",
            scaleBase = 1,
            scaleDetail = 0.18,
            thresh = 0.8,
            ratio1 = 0.4,
            ratio2 = 0.6,
            spawnProbability = 1,
            seedOffset = 700
        },
    }
}