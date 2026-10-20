function QWeather.isAdmin(src)
    return src == 0 or IsPlayerAceAllowed(src, Config.ace)
end

local function snapshot()
    local state = QState.get()
    local clock = GlobalState[QWeather.keys.clock]
    local settings = QSettings.get()
    return {
        weather = state.weather,
        hour = state.hour,
        minute = state.minute,
        ms = clock and clock.ms or 5000,
        freeze = state.freeze,
        blackout = state.blackout,
        dynamic = state.dynamic,
        realTime = state.realTime,
        realWeather = state.realWeather,
        tsunami = QTsunami.active(),
        canRealWeather = settings.real.apiKey ~= '' and settings.real.city ~= '',
        real = QReal.last(),
    }
end

QPanel = { snapshot = snapshot }

local CONTROLS = {
    weather = function(value) return QState.setWeather(value, { instant = false }) end,
    time = function(value)
        if type(value) ~= 'table' or QState.get().realTime then return false end
        local ok = QState.setTime(value.hour, value.minute, value.jump == true)
        if ok then QClock.reset() end
        return ok
    end,
    flag = function(value)
        if type(value) ~= 'table' then return false end
        if value.name == 'realWeather' and value.value and not snapshot().canRealWeather then return false end
        return QState.setFlag(value.name, value.value)
    end,
    tsunami = function(value)
        if value then return QTsunami.start(QSettings.get().tsunami.minutes) end
        return QTsunami.stop()
    end,
}

lib.callback.register('mri_Qweather:server:getState', function(src)
    if not QWeather.isAdmin(src) then return false end
    return snapshot()
end)

lib.callback.register('mri_Qweather:server:control', function(src, action, value)
    if not QWeather.isAdmin(src) or not CONTROLS[action] then return false end
    return { ok = CONTROLS[action](value) == true, state = snapshot() }
end)

lib.callback.register('mri_Qweather:server:canManage', function(src)
    return QWeather.isAdmin(src)
end)

local function panelSettings()
    local copy = json.decode(json.encode(QSettings.get()))
    copy.real.hasApiKey = copy.real.apiKey ~= ''
    copy.real.apiKey = ''
    return copy
end

lib.callback.register('mri_Qweather:server:getSettings', function(src)
    if not QWeather.isAdmin(src) then return false end
    return panelSettings()
end)

lib.callback.register('mri_Qweather:server:saveSettings', function(src, section, values)
    if not QWeather.isAdmin(src) then return false end
    return { ok = QSettings.save(section, values), settings = panelSettings() }
end)

local function forecastPayload()
    return { enabled = QForecast.running(), events = QForecast.queue() }
end

lib.callback.register('mri_Qweather:server:getForecast', function(src)
    if not QWeather.isAdmin(src) then return false end
    return forecastPayload()
end)

lib.callback.register('mri_Qweather:server:forecast', function(src, action, index, value)
    if not QWeather.isAdmin(src) then return false end
    local ok = false
    if action == 'weather' then ok = QForecast.setWeather(index, value)
    elseif action == 'time' then ok = QForecast.setTime(index, value)
    elseif action == 'remove' then ok = QForecast.remove(index) end
    local payload = forecastPayload()
    payload.ok = ok
    return payload
end)

RegisterCommand(Config.command, function(src)
    if src == 0 then return end
    if not QWeather.isAdmin(src) then
        QWeather.notify(src, 'error', locale('invalid_permissions'))
        return
    end
    TriggerClientEvent('mri_Qweather:client:open', src, snapshot())
end, false)

-- Tab in the mri_Qadmin panel. RegisterPlugin keeps one entry per id, so the two triggers below are safe together.
local function registerPlugin()
    if GetResourceState('mri_Qadmin') ~= 'started' then return end
    local ok, result = pcall(function()
        return exports.mri_Qadmin:RegisterPlugin({
            id = 'weather',
            label = locale('title'),
            icon = 'cloud-sun',
            resource = QWeather.resource,
            htmlPath = 'web/build/index.html',
            requiredPerms = { QWeather.resource .. '.admin', 'command' },
            description = locale('plugin_description'),
        })
    end)
    if not ok or result == false then
        print(('[%s] mri_Qadmin recusou o plugin: %s'):format(QWeather.resource, tostring(result)))
    end
end

CreateThread(registerPlugin)
AddEventHandler('mri_Qadmin:server:pluginsReady', registerPlugin)

-- Suite colours: players read the replicated convars when the panel opens; only runtime changes are pushed.
AddConvarChangeListener('mri:color', function()
    TriggerClientEvent('mri_Qweather:client:theme', -1)
end)
AddConvarChangeListener('mri:backgroundColor', function()
    TriggerClientEvent('mri_Qweather:client:theme', -1)
end)

function QWeather.notify(src, kind, message)
    if src == 0 then return print(message) end
    lib.notify(src, { title = locale('title'), description = message, type = kind })
end
