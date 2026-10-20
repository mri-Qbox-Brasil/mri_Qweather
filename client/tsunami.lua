QClientTsunami = {}

local running = nil

function QClientTsunami.active()
    return running ~= nil
end

local function start(data)
    local id = {}
    running = id
    local total = tonumber(data.seconds) or 120
    local left = math.max(0, math.min(total, (tonumber(data.endsAt) or 0) - GetCloudTimeAsInt()))
    local elapsed = total - left
    local storm = GetGameBuildNumber() >= 3258 and 'RAIN_HALLOWEEN' or 'HALLOWEEN'
    -- The storm takes the first quarter to build up; joining later shows it already built.
    QClientWeather.force(storm, math.max(0, total / 4 - elapsed))
    if elapsed < 5 then
        lib.notify({ title = locale('tsunami_title'), description = locale(data.restart and 'tsunami_restart' or 'tsunami_alert', math.max(1, math.ceil(left / 60))), type = 'warning', duration = 15000 })
    end
    -- Halfway through, lights go out and the siren plays until the end.
    SetTimeout(math.max(0, math.floor((total / 2 - elapsed) * 1000)), function()
        if running ~= id then return end
        SetArtificialLightsState(true)
        SetArtificialLightsStateAffectsVehicles(true)
        SendNUIMessage({ action = 'siren' })
    end)
end

local function stop()
    if not running then return end
    running = nil
    SendNUIMessage({ action = 'sirenStop' })
    QClientWeather.restoreBlackout()
    QClientWeather.refresh()
end

local function apply(value)
    if type(value) == 'table' then start(value) else stop() end
end

AddStateBagChangeHandler(QWeather.keys.tsunami, 'global', function(_, _, value)
    apply(value)
end)

AddEventHandler('onClientResourceStart', function(name)
    if name == QWeather.resource and type(GlobalState[QWeather.keys.tsunami]) == 'table' then
        apply(GlobalState[QWeather.keys.tsunami])
    end
end)
