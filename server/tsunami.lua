QTsunami = {}

local key = QWeather.keys.tsunami

GlobalState[key] = false

function QTsunami.active()
    return GlobalState[key] ~= false and GlobalState[key] ~= nil
end

-- The clients run the warning: storm builds up, then lights go out and the siren plays.
function QTsunami.start(minutes)
    if not QSettings.get().tsunami.enabled then return false end
    GlobalState[key] = { minutes = minutes, seq = GetGameTimer() }
    return true
end

function QTsunami.stop()
    GlobalState[key] = false
    return true
end

AddEventHandler('txAdmin:events:scheduledRestart', function(data)
    local cfg = QSettings.get().tsunami
    if cfg.enabled and tonumber(data.secondsRemaining) == cfg.minutes * 60 then QTsunami.start(cfg.minutes) end
end)

AddEventHandler('txAdmin:events:skippedNextScheduledRestart', function()
    QTsunami.stop()
end)
