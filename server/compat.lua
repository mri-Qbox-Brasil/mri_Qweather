-- Interface other resources were written against (qb-weathersync, cd_easytime, Renewed-Weathersync, mri_Qweather exports).

function SetWeather(weather)
    return QState.setWeather(weather, { instant = true })
end

function SetTime(hour, minute)
    local ok = QState.setTime(hour, minute or 0, true)
    if ok then QClock.reset() end
    return ok
end

function SetBlackout(state) return QState.setFlag('blackout', state == true) end
function SetTimeFreeze(state) return QState.setFlag('freeze', state == true) end
function SetDynamic(state) return QState.setFlag('dynamic', state == true) end

-- Milliseconds per game minute for the whole day (Renewed's timeScale), as the closest choices of the panel.
function SetTimeScale(ms)
    ms = tonumber(ms)
    if not ms or ms < 1000 then return false end
    local time = QSettings.get().time
    local nightHours = (time.nightEnd - time.nightStart) % 24
    local values = json.decode(json.encode(time))
    values.dayMinutes = math.floor(ms * (24 - nightHours) * 60 / 60000 + 0.5)
    values.nightMinutes = math.floor(ms * nightHours * 60 / 60000 + 0.5)
    return QSettings.save('time', values)
end

function GetWeather()
    local state = QState.get()
    return { weather = state.weather, hours = state.hour, mins = state.minute, blackout = state.blackout, freeze = state.freeze, dynamic = state.dynamic }
end

GetAllData = GetWeather

function GetRealData()
    local reading = QReal.fetch()
    if not reading then return nil end
    local state = QState.get()
    return {
        hours = state.hour, mins = state.minute, gta_weather = reading.weather,
        real_weather = reading.description, real_weather_description = reading.description,
        country = reading.country, city = reading.city,
    }
end

function GetForecastQueue()
    local events = {}
    for i, e in ipairs(QForecast.queue()) do events[i] = { weather = e.weather, time = e.time, hasSnow = e.hasSnow } end
    local state = QState.get()
    local clock = GlobalState[QWeather.keys.clock]
    return { enabled = QForecast.running(), events = events, timeScale = clock and clock.ms, time = { hour = state.hour, minute = state.minute } }
end

-- Exports under another resource name: provide does not forward them, the export event does.
local function exportAs(resource, name, fn)
    AddEventHandler(('__cfx_export_%s_%s'):format(resource, name), function(setCB) setCB(fn) end)
end

exportAs('qb-weathersync', 'setWeather', SetWeather)
exportAs('qb-weathersync', 'setTime', SetTime)
exportAs('qb-weathersync', 'setBlackout', function(state) return SetBlackout(state and true or false) end)
exportAs('qb-weathersync', 'setTimeFreeze', function(state) return SetTimeFreeze(state and true or false) end)
exportAs('qb-weathersync', 'setDynamicWeather', function(state) return SetDynamic(state and true or false) end)
exportAs('qb-weathersync', 'getWeatherState', function() return QState.get().weather end)
exportAs('qb-weathersync', 'getBlackoutState', function() return QState.get().blackout end)
exportAs('qb-weathersync', 'getTimeFreezeState', function() return QState.get().freeze end)
exportAs('qb-weathersync', 'getDynamicWeather', function() return QState.get().dynamic end)
exportAs('qb-weathersync', 'getTime', function() return QState.get().hour, QState.get().minute end)
exportAs('qb-weathersync', 'nextWeatherStage', function() QForecast.remove(1) end)
exportAs('cd_easytime', 'GetWeather', GetWeather)

RegisterNetEvent('qb-weathersync:server:setWeather', function(weather)
    if QWeather.isAdmin(source) then SetWeather(weather) end
end)

RegisterNetEvent('qb-weathersync:server:setTime', function(hour, minute)
    if QWeather.isAdmin(source) then SetTime(tonumber(hour), tonumber(minute) or 0) end
end)

-- Renewed-Weathersync state bags (the phone app reads weather and currentTime).
CreateThread(function()
    local last = {}
    local function set(key, value, compare)
        if last[key] == compare then return end
        last[key] = compare
        GlobalState[key] = value
    end
    while true do
        local state = QState.get()
        local clock = GlobalState[QWeather.keys.clock]
        set('weather', { weather = state.weather, time = 9999999 }, state.weather)
        set('currentTime', { hour = state.hour, minute = state.minute }, state.hour * 60 + state.minute)
        set('freezeTime', state.freeze, state.freeze)
        set('blackOut', state.blackout, state.blackout)
        if clock then set('timeScale', clock.ms, clock.ms) end
        Wait(1000)
    end
end)

-- Text commands the old weather scripts had, behind the same permission as the panel.
local function adminCommand(name, handler)
    RegisterCommand(name, function(src, args)
        if not QWeather.isAdmin(src) then return QWeather.notify(src, 'error', locale('invalid_permissions')) end
        handler(src, args)
    end, false)
end

adminCommand('time', function(src, args)
    local hour, minute = tonumber(args[1]), tonumber(args[2]) or 0
    if not hour then return QWeather.notify(src, 'error', locale('time_usage')) end
    hour, minute = math.floor(hour) % 24, math.floor(minute)
    if not SetTime(hour, minute) then return QWeather.notify(src, 'error', locale('time_invalid')) end
    QWeather.notify(src, 'success', locale('time_set', ('%02d:%02d'):format(hour, minute)))
end)

for name, at in pairs({ morning = 9, noon = 12, evening = 18, night = 23 }) do
    adminCommand(name, function(src)
        SetTime(at, 0)
        QWeather.notify(src, 'success', locale('time_set', ('%02d:00'):format(at)))
    end)
end

adminCommand('weather', function(src, args)
    local weather = args[1] and args[1]:upper()
    -- Renewed opened its menu on a bare /weather, and the F10 menu of mri_Qbox relies on it.
    if not weather and src ~= 0 then return TriggerClientEvent('mri_Qweather:client:open', src, QPanel.snapshot()) end
    if not weather then return QWeather.notify(src, 'error', locale('weather_usage')) end
    if not SetWeather(weather) then return QWeather.notify(src, 'error', locale('weather_invalid', weather)) end
    QWeather.notify(src, 'success', locale('weather_set', weather))
end)

adminCommand('timescale', function(src, args)
    local ms = tonumber(args[1])
    if not ms then return QWeather.notify(src, 'error', locale('timescale_usage')) end
    if not SetTimeScale(ms) then return QWeather.notify(src, 'error', locale('timescale_invalid')) end
    QWeather.notify(src, 'success', locale('timescale_set', math.floor(ms)))
end)

adminCommand('freezetime', function(src, args)
    local state = args[1] == '1' or args[1] == 'true'
    SetTimeFreeze(state)
    QWeather.notify(src, 'success', locale(state and 'time_frozen' or 'time_unfrozen'))
end)
