QClientWeather = {}

local keys = QWeather.keys
local shown = nil       -- weather on screen (zone or global)
local eventSnow = false -- snow on the ground from the forecast event
local snowOn = false

-- The only place that touches the snow natives: two owners used to undo each other and leave trails stuck on.
-- No ForceSnowPass: Los Santos has no snow textures and the asphalt turns black.
local function setSnow(state)
    if state == snowOn then return end
    snowOn = state
    SetForceVehicleTrails(state)
    SetForcePedFootstepsTracks(state)
    if state then
        RequestScriptAudioBank('ICE_FOOTSTEPS', false)
        RequestScriptAudioBank('SNOW_FOOTSTEPS', false)
        lib.requestNamedPtfxAsset('core_snow', 1000)
        UseParticleFxAsset('core_snow')
        if GetResourceState('nve_iced_alamo') == 'started' then RequestIpl('alamo_ice') end
    else
        ReleaseNamedScriptAudioBank('ICE_FOOTSTEPS')
        ReleaseNamedScriptAudioBank('SNOW_FOOTSTEPS')
        RemoveNamedPtfxAsset('core_snow')
        if IsIplActive('alamo_ice') then RemoveIpl('alamo_ice') end
    end
end

local function show(weather, seconds)
    shown = weather
    ClearOverrideWeather()
    if seconds <= 0 then
        ClearWeatherTypePersist()
        SetWeatherTypeNowPersist(weather)
    else
        SetWeatherTypeOvertimePersist(weather, seconds + 0.0)
    end
    setSnow(QWeather.snowGround[weather] == true or eventSnow)
end

function QClientWeather.shown()
    return shown
end

-- What the player should see now: tsunami and paused scenes win, then the zone, then the city weather.
function QClientWeather.target()
    if QClient.paused then return 'EXTRASUNNY' end
    local weather = QClient.weather()
    return QClientZones and QClientZones.override(weather) or weather
end

-- Re-evaluates the sky; `seconds` nil uses the transition of the settings.
function QClientWeather.refresh(seconds)
    if QClientTsunami and QClientTsunami.active() then return end
    local target = QClientWeather.target()
    if target == shown then return setSnow(QWeather.snowGround[target] == true or eventSnow) end
    show(target, seconds or QClient.settings().weather.transition)
end

function QClientWeather.force(weather, seconds)
    show(weather, seconds)
end

AddStateBagChangeHandler(keys.weather, 'global', function(_, _, value)
    if type(value) ~= 'table' then return end
    eventSnow = value.snow == true
    if value.wind then SetWindSpeed(value.wind + 0.0) end
    if value.windDirection then SetWindDirection(math.rad(value.windDirection)) end
    -- Statebag handlers run before GlobalState holds the new value: read it on the next tick.
    SetTimeout(0, function() QClientWeather.refresh(value.instant and 0 or nil) end)
end)

local function applyBlackout(state)
    SetArtificialLightsState(state == true)
    SetArtificialLightsStateAffectsVehicles(QClient.settings().blackout.vehicles == true)
end

AddStateBagChangeHandler(keys.blackout, 'global', function(_, _, value)
    if QClientTsunami and QClientTsunami.active() then return end
    applyBlackout(value)
end)

AddEventHandler('mri_Qweather:client:pauseChanged', function()
    QClientWeather.refresh(0)
end)

function QClientWeather.restoreBlackout()
    applyBlackout(GlobalState[keys.blackout])
end

AddEventHandler('onClientResourceStart', function(name)
    if name ~= QWeather.resource then return end
    -- Trails left on by an older session stay on the client until something turns them off.
    SetForceVehicleTrails(false)
    SetForcePedFootstepsTracks(false)
    SetRainLevel(-1.0)
    QClientWeather.refresh(0)
    QClientWeather.restoreBlackout()
end)

AddEventHandler('onClientResourceStop', function(name)
    if name ~= QWeather.resource then return end
    setSnow(false)
end)
