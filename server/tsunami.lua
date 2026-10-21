QTsunami = {}

local key = QWeather.keys.tsunami

GlobalState[key] = false

function QTsunami.active()
    return type(GlobalState[key]) == 'table'
end

-- The clients run the warning from endsAt (unix time), so a player who joins halfway sees the same moment.
-- restart: a txAdmin restart ends it; otherwise it calms down by itself when the time is up.
function QTsunami.start(seconds, restart)
    seconds = math.floor(tonumber(seconds) or 0)
    if seconds < 10 then return false end
    local endsAt = os.time() + seconds
    local cfg = QSettings.get().tsunami
    GlobalState[key] = { seconds = seconds, endsAt = endsAt, restart = restart == true, flood = cfg.flood, rise = cfg.rise, waves = cfg.waves }
    SetTimeout((seconds + (restart and 120 or 0)) * 1000, function()
        local current = GlobalState[key]
        if type(current) == 'table' and current.endsAt == endsAt then QTsunami.stop() end
    end)
    return true
end

function QTsunami.stop()
    GlobalState[key] = false
    return true
end

AddEventHandler('txAdmin:events:scheduledRestart', function(data)
    local cfg = QSettings.get().tsunami
    local remaining = tonumber(data.secondsRemaining)
    if not cfg.enabled or not remaining or QTsunami.active() then return end
    -- A restart scheduled with less time than the setting still gets the warning, just shorter.
    if remaining <= cfg.minutes * 60 then QTsunami.start(remaining, true) end
end)

AddEventHandler('txAdmin:events:skippedNextScheduledRestart', function()
    QTsunami.stop()
end)
