QForecast = {}

-- Where each weather can go next, so the sky changes the way it would outside (no sun straight into a storm).
local NEXT = {
    EXTRASUNNY = { 'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'SMOG' },
    CLEAR = { 'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'SMOG', 'FOGGY' },
    CLOUDS = { 'CLEAR', 'CLOUDS', 'OVERCAST', 'FOGGY', 'SNOWLIGHT' },
    OVERCAST = { 'CLOUDS', 'OVERCAST', 'CLEARING', 'RAIN', 'SNOWLIGHT' },
    SMOG = { 'EXTRASUNNY', 'CLEAR', 'CLOUDS' },
    FOGGY = { 'CLEAR', 'CLOUDS', 'OVERCAST' },
    CLEARING = { 'CLEAR', 'CLOUDS', 'OVERCAST' },
    RAIN = { 'RAIN', 'THUNDER', 'CLEARING' },
    THUNDER = { 'RAIN', 'CLEARING' },
    SNOWLIGHT = { 'CLOUDS', 'OVERCAST', 'SNOW', 'SNOWLIGHT' },
    SNOW = { 'SNOWLIGHT', 'SNOW', 'BLIZZARD' },
    BLIZZARD = { 'SNOW' },
    XMAS = { 'XMAS', 'SNOW', 'SNOWLIGHT' },
}

-- Steady wind per weather (m/s), shuffled a little on each event.
local WIND = {
    EXTRASUNNY = 0.5, CLEAR = 1.0, CLOUDS = 2.0, OVERCAST = 3.0, SMOG = 0.5, FOGGY = 0.5, CLEARING = 3.0,
    RAIN = 5.0, THUNDER = 9.0, SNOWLIGHT = 2.0, SNOW = 4.0, BLIZZARD = 10.0, XMAS = 2.0,
}

local LENGTHS = { short = { 8, 15 }, normal = { 15, 30 }, long = { 30, 60 } }
local QUEUE_SIZE = 12
local SNOW_FAMILY = { SNOWLIGHT = true, SNOW = true, BLIZZARD = true, XMAS = true }

local queue = {}
local startedAt = os.time()
local lastRainAt = nil

local function rainAllowed(minutesAhead)
    local cfg = QSettings.get().weather
    local at = os.time() + minutesAhead * 60
    if at - startedAt < cfg.rainAfterRestart * 60 then return false end
    return not lastRainAt or at - lastRainAt >= cfg.rainGap * 60
end

local function decemberSnow()
    return QSettings.get().weather.decemberSnow and tonumber(os.date('%m')) == 12
end

local function weightOf(weather, minutesAhead)
    local cfg = QSettings.get().weather
    if decemberSnow() then return SNOW_FAMILY[weather] and 3 or 0 end
    if QWeather.rainy[weather] and weather ~= 'CLEARING' and not rainAllowed(minutesAhead) then return 0 end
    return cfg.frequency[weather] or 0
end

local function choose(from, minutesAhead)
    local options = NEXT[from] or NEXT.CLEAR
    local total = 0
    for i = 1, #options do total += weightOf(options[i], minutesAhead) end
    -- Nothing allowed from here (everything set to "never"): walk back to fair weather.
    if total == 0 then
        if decemberSnow() then return 'SNOW' end
        return from == 'CLEAR' and 'EXTRASUNNY' or 'CLEAR'
    end
    local roll = math.random() * total
    for i = 1, #options do
        roll -= weightOf(options[i], minutesAhead)
        if roll <= 0 then return options[i] end
    end
    return options[#options]
end

local function makeEvent(weather)
    local range = LENGTHS[QSettings.get().weather.eventMinutes] or LENGTHS.normal
    return {
        weather = weather,
        time = math.random(range[1], range[2]),
        windSpeed = (WIND[weather] or 1.0) * (0.75 + math.random() * 0.5),
        windDirection = math.random(0, 359),
        hasSnow = QWeather.snowGround[weather] == true,
    }
end

local function minutesUntil(index)
    local total = 0
    for i = 1, index - 1 do total += queue[i].time end
    return total
end

local function fill()
    while #queue < QUEUE_SIZE do
        local from = queue[#queue] and queue[#queue].weather or QState.get().weather
        queue[#queue + 1] = makeEvent(choose(from, minutesUntil(#queue + 1)))
    end
end

local function apply(event)
    if QWeather.rainy[event.weather] then lastRainAt = os.time() end
    QState.setWeather(event.weather, { wind = event.windSpeed, windDirection = event.windDirection, snow = event.hasSnow })
end

local function running()
    local state = QState.get()
    return state.dynamic and not state.realWeather
end

CreateThread(function()
    math.randomseed(os.time())
    fill()
    local active = false
    while true do
        if running() then
            if not active then
                active = true
                apply(queue[1])
            else
                queue[1].time -= 1
                if queue[1].time <= 0 then
                    table.remove(queue, 1)
                    fill()
                    apply(queue[1])
                end
            end
            Wait(60000)
        else
            active = false
            Wait(1000)
        end
    end
end)

-- A setting change (frequency, length) is felt from the next events on, the current one stays.
AddEventHandler('mri_Qweather:server:settingsChanged', function(section)
    if section ~= 'weather' then return end
    for i = #queue, 2, -1 do queue[i] = nil end
    fill()
end)

local function copy()
    local out = {}
    for i = 1, #queue do
        local e = queue[i]
        out[i] = { weather = e.weather, time = e.time, windSpeed = e.windSpeed, windDirection = e.windDirection, hasSnow = e.hasSnow }
    end
    return out
end

function QForecast.queue()
    return copy()
end

function QForecast.running()
    return running()
end

function QForecast.setWeather(index, weather)
    index = tonumber(index)
    if not index or not queue[index] or not QWeather.isValid(weather) then return false end
    local event = makeEvent(weather)
    event.time = queue[index].time
    queue[index] = event
    if index == 1 and running() then apply(event) end
    return true
end

function QForecast.setTime(index, minutes)
    index, minutes = tonumber(index), math.floor(tonumber(minutes) or 0)
    if not index or not queue[index] or minutes < 1 then return false end
    queue[index].time = math.min(minutes, 1440)
    return true
end

function QForecast.remove(index)
    index = tonumber(index)
    if not index or not queue[index] then return false end
    table.remove(queue, index)
    fill()
    if index == 1 and running() then apply(queue[1]) end
    return true
end
