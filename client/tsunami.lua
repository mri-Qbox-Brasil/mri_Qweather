QClientTsunami = {}

local running = nil

function QClientTsunami.active()
    return running ~= nil
end

local function start(data)
    local id = {}
    running = id
    local total = (tonumber(data.minutes) or 2) * 60000
    local storm = GetGameBuildNumber() >= 3258 and 'RAIN_HALLOWEEN' or 'HALLOWEEN'
    QClientWeather.force(storm, total / 4000)
    -- Halfway through, lights go out and the siren plays until the restart.
    SetTimeout(math.floor(total / 2), function()
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
