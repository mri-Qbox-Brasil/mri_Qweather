QClient = {
    paused = false,
    pausedHour = nil,
}

local keys = QWeather.keys

function QClient.weather()
    local w = GlobalState[keys.weather]
    return w and w.weather or 'CLEAR'
end

function QClient.settings()
    return GlobalState[keys.settings] or Config.settings
end

-- Other scripts take the sky for a scene (character select, interiors) and give it back.
function QClient.setPaused(paused, hour)
    paused = paused == true
    if paused == QClient.paused and hour == QClient.pausedHour then return end
    QClient.paused = paused
    QClient.pausedHour = paused and (tonumber(hour) or 20) or nil
    TriggerEvent('mri_Qweather:client:pauseChanged', paused)
end

RegisterNetEvent('cd_easytime:PauseSync', function(paused, hour) QClient.setPaused(paused, hour) end)
RegisterNetEvent('qb-weathersync:client:DisableSync', function() QClient.setPaused(true) end)
RegisterNetEvent('qb-weathersync:client:EnableSync', function() QClient.setPaused(false) end)
RegisterNetEvent('vSync:toggle', function(enabled) QClient.setPaused(not enabled) end)

function GetPauseSyncState()
    return QClient.paused
end
