QState = {}

local KVP = 'state'
local keys = QWeather.keys

local state = {
    weather = 'CLEAR',
    hour = 8,
    minute = 0,
    freeze = false,
    blackout = false,
    dynamic = true,
    realTime = false,
    realWeather = false,
}

-- Version 2 kept its state in settings.txt with other names; read it once when there is nothing saved yet.
local function legacy()
    local raw = LoadResourceFile(QWeather.resource, 'settings.txt')
    local ok, old = pcall(json.decode, raw or '')
    if not ok or type(old) ~= 'table' then return {} end
    return { weather = old.weather, hour = old.hours, minute = old.mins, freeze = old.freeze, blackout = old.blackout, dynamic = old.dynamic }
end

do
    local saved = GetResourceKvpString(KVP)
    local ok, stored = true, legacy()
    if saved then ok, stored = pcall(json.decode, saved) end
    if ok and type(stored) == 'table' then
        if QWeather.isValid(stored.weather) then state.weather = stored.weather end
        local hour, minute = tonumber(stored.hour), tonumber(stored.minute)
        if hour and hour >= 0 and hour < 24 then state.hour = math.floor(hour) end
        if minute and minute >= 0 and minute < 60 then state.minute = math.floor(minute) end
        for _, flag in ipairs({ 'freeze', 'blackout', 'dynamic', 'realTime', 'realWeather' }) do
            if type(stored[flag]) == 'boolean' then state[flag] = stored[flag] end
        end
    end
end

local dirty = false

local function save()
    dirty = true
end

-- Writes at most once every 10 s: the clock changes the state every few seconds.
CreateThread(function()
    while true do
        Wait(10000)
        if dirty then
            dirty = false
            SetResourceKvp(KVP, json.encode(state))
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name == QWeather.resource then SetResourceKvp(KVP, json.encode(state)) end
end)

local weatherSeq, clockSeq = 0, 0

-- extra: { instant = bool, wind = number, windDirection = number, snow = bool }
local function publishWeather(extra)
    weatherSeq += 1
    extra = extra or {}
    GlobalState[keys.weather] = {
        weather = state.weather,
        instant = extra.instant == true,
        wind = extra.wind,
        windDirection = extra.windDirection,
        snow = extra.snow == true,
        seq = weatherSeq,
    }
end

local function publishClock(jump)
    clockSeq += 1
    GlobalState[keys.clock] = {
        hour = state.hour,
        minute = state.minute,
        ms = QWeather.msPerMinute(state.hour, QSettings.get().time),
        frozen = state.freeze,
        jump = jump == true,
        seq = clockSeq,
    }
end

publishWeather({ instant = true })
publishClock(true)
GlobalState[keys.blackout] = state.blackout

function QState.get()
    return state
end

function QState.setWeather(weather, extra)
    if not QWeather.isValid(weather) then return false end
    state.weather = weather
    save()
    publishWeather(extra)
    TriggerEvent('mri_Qweather:server:weatherChanged', weather)
    return true
end

function QState.setTime(hour, minute, jump)
    hour, minute = tonumber(hour), tonumber(minute)
    if not hour or not minute then return false end
    hour, minute = math.floor(hour), math.floor(minute)
    if hour < 0 or hour > 23 or minute < 0 or minute > 59 then return false end
    state.hour, state.minute = hour, minute
    save()
    publishClock(jump)
    return true
end

-- One game minute forward, from the clock loop.
function QState.tick()
    local total = (state.hour * 60 + state.minute + 1) % 1440
    state.hour, state.minute = total // 60, total % 60
    save()
    publishClock(false)
end

function QState.republishClock()
    publishClock(false)
end

local FLAGS = { freeze = true, blackout = true, dynamic = true, realTime = true, realWeather = true }

function QState.setFlag(flag, value)
    if not FLAGS[flag] or type(value) ~= 'boolean' then return false end
    state[flag] = value
    save()
    if flag == 'blackout' then GlobalState[keys.blackout] = value end
    if flag == 'freeze' then publishClock(false) end
    TriggerEvent('mri_Qweather:server:flagChanged', flag, value)
    return true
end
