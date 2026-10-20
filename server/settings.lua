QSettings = {}

local KVP = 'settings'
local DEFAULTS = Config.settings

-- Choices the panel offers; anything else sent to the server falls back to the saved value.
local CHOICES = {
    dayMinutes = { 24, 48, 60, 80, 120, 180, 240 },
    nightMinutes = { 12, 24, 30, 40, 60, 90, 120 },
    hours = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 },
    utcOffset = { -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 },
    transition = { 0, 15, 30, 45, 60, 120 },
    eventMinutes = { 'short', 'normal', 'long' },
    rainGap = { 30, 60, 120, 240, 480 },
    rainAfterRestart = { 0, 30, 60, 120, 240 },
    frequency = { 0, 1, 2, 3 },
    checkMinutes = { 10, 15, 30, 60 },
    tsunamiMinutes = { 1, 2, 3, 5 },
    zoneTransition = { 5, 15, 25, 45 },
    unit = { 'C', 'F' },
}

local function pick(list, value, fallback)
    for i = 1, #list do
        if list[i] == value then return value end
    end
    return fallback
end

local function bool(value, fallback)
    if type(value) == 'boolean' then return value end
    return fallback
end

local function text(value, fallback, max)
    if type(value) ~= 'string' then return fallback end
    return value:gsub('^%s+', ''):gsub('%s+$', ''):sub(1, max)
end

local CLEAN = {
    time = function(v, old)
        return {
            dayMinutes = pick(CHOICES.dayMinutes, tonumber(v.dayMinutes), old.dayMinutes),
            nightMinutes = pick(CHOICES.nightMinutes, tonumber(v.nightMinutes), old.nightMinutes),
            nightStart = pick(CHOICES.hours, tonumber(v.nightStart), old.nightStart),
            nightEnd = pick(CHOICES.hours, tonumber(v.nightEnd), old.nightEnd),
            utcOffset = pick(CHOICES.utcOffset, tonumber(v.utcOffset), old.utcOffset),
        }
    end,
    weather = function(v, old)
        local frequency = {}
        local given = type(v.frequency) == 'table' and v.frequency or {}
        for name, value in pairs(old.frequency) do
            frequency[name] = pick(CHOICES.frequency, tonumber(given[name]), value)
        end
        return {
            transition = pick(CHOICES.transition, tonumber(v.transition), old.transition),
            eventMinutes = pick(CHOICES.eventMinutes, v.eventMinutes, old.eventMinutes),
            rainGap = pick(CHOICES.rainGap, tonumber(v.rainGap), old.rainGap),
            rainAfterRestart = pick(CHOICES.rainAfterRestart, tonumber(v.rainAfterRestart), old.rainAfterRestart),
            decemberSnow = bool(v.decemberSnow, old.decemberSnow),
            frequency = frequency,
        }
    end,
    real = function(v, old)
        return {
            city = text(v.city, old.city, 60),
            -- An empty key from the panel means "keep": the panel never receives the saved one.
            apiKey = (type(v.apiKey) == 'string' and v.apiKey ~= '') and text(v.apiKey, old.apiKey, 64) or old.apiKey,
            checkMinutes = pick(CHOICES.checkMinutes, tonumber(v.checkMinutes), old.checkMinutes),
        }
    end,
    tsunami = function(v, old)
        return {
            enabled = bool(v.enabled, old.enabled),
            minutes = pick(CHOICES.tsunamiMinutes, tonumber(v.minutes), old.minutes),
        }
    end,
    zones = function(v, old)
        return {
            enabled = bool(v.enabled, old.enabled),
            transition = pick(CHOICES.zoneTransition, tonumber(v.transition), old.transition),
        }
    end,
    blackout = function(v, old)
        return { vehicles = bool(v.vehicles, old.vehicles) }
    end,
    temperature = function(v, old)
        return { unit = pick(CHOICES.unit, v.unit, old.unit) }
    end,
}

local settings = {}

-- Players get everything but the API key.
local function publish()
    local public = json.decode(json.encode(settings))
    public.real.apiKey = nil
    public.real.hasApiKey = settings.real.apiKey ~= ''
    GlobalState[QWeather.keys.settings] = public
end

local function load()
    local ok, stored = pcall(json.decode, GetResourceKvpString(KVP) or '{}')
    stored = ok and type(stored) == 'table' and stored or {}
    for section, clean in pairs(CLEAN) do
        local given = type(stored[section]) == 'table' and stored[section] or {}
        settings[section] = clean(given, DEFAULTS[section])
    end
end

load()
publish()

function QSettings.get()
    return settings
end

function QSettings.public()
    return GlobalState[QWeather.keys.settings]
end

function QSettings.save(section, values)
    local clean = CLEAN[section]
    if not clean or type(values) ~= 'table' then return false end
    settings[section] = clean(values, settings[section])
    SetResourceKvp(KVP, json.encode(settings))
    publish()
    TriggerEvent('mri_Qweather:server:settingsChanged', section)
    return true
end
