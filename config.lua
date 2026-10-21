Config = {}

-- Command that opens the panel; the ACE below is what lets an admin use it.
Config.command = 'clima'
Config.ace = 'command.clima'

-- First values only: from the first start on, the Ajustes tab of the panel owns them.
Config.settings = {
    time = {
        dayMinutes = 80,   -- real minutes the day lasts
        nightMinutes = 40, -- real minutes the night lasts
        nightStart = 22,
        nightEnd = 6,
        utcOffset = -3,    -- used by "real time"
    },
    weather = {
        transition = 45,   -- seconds a weather change takes
        eventMinutes = 'normal',
        rainGap = 120,     -- real minutes between two rains
        rainAfterRestart = 60,
        decemberSnow = false,
        -- how often each weather comes up in the automatic forecast: 0 never, 1 rare, 2 normal, 3 often
        frequency = {
            EXTRASUNNY = 3, CLEAR = 3, CLOUDS = 2, OVERCAST = 2, SMOG = 1, FOGGY = 1,
            CLEARING = 1, RAIN = 1, THUNDER = 1, SNOWLIGHT = 0, SNOW = 0, BLIZZARD = 0, XMAS = 0,
        },
    },
    real = {
        city = '',
        apiKey = '',       -- openweathermap.org key, never sent to players
        checkMinutes = 30,
    },
    tsunami = {
        enabled = true,
        minutes = 2,       -- minutes before a scheduled restart
        flood = 8,         -- metres the sea rises (0 = no flood)
        rise = 0,          -- seconds the sea takes to reach that height (0 = the whole warning)
        waves = 'strong', -- normal, strong or huge
    },
    zones = {
        enabled = true,
        transition = 25,
    },
    blackout = {
        vehicles = false,
    },
    temperature = {
        unit = 'C',
    },
}

-- Starting weather zones; the Zonas tab saves its own list in data/zones.json after the first start.
Config.zones = {
    checkInterval = 1500,
    natives = {
        MTCHIL = { rule = { mode = 'bias', allow = { 'OVERCAST', 'CLOUDS', 'SNOWLIGHT', 'SNOW', 'FOGGY' }, fallback = 'SNOWLIGHT' }, tempMod = -8 },
    },
    custom = {},
}

-- Simulated temperature (GTA has none). Code constants, not an owner decision.
Config.temperature = {
    base = {
        EXTRASUNNY = 32, CLEAR = 26, CLOUDS = 22, OVERCAST = 18, SMOG = 20, FOGGY = 14, CLEARING = 17,
        RAIN = 15, THUNDER = 14, SNOWLIGHT = 1, SNOW = -2, BLIZZARD = -8, XMAS = -3, NEUTRAL = 17,
        HALLOWEEN = 12, RAIN_HALLOWEEN = 12, SNOW_HALLOWEEN = -3,
    },
    fallback = 20,
    dayNightAmplitude = 6,
    peakHour = 15,
    monthOffset = { [12] = -6, [1] = -7, [2] = -6, [6] = 3, [7] = 5, [8] = 5 },
    altitude = { lapsePerKm = 6.5, seaLevelZ = 0.0 },
    windChillFactor = 0.7,
    waterMod = -4,
    interior = 21,
    updateInterval = 2000,
}
