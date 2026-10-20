QClientClock = {}

-- Anchor of the server minute: seconds in between are filled locally so the sky moves smoothly.
local anchor = { hour = 8, minute = 0, at = 0, ms = 5000, frozen = false }
local transition = nil

local function toSeconds(hour, minute, second)
    return hour * 3600 + minute * 60 + (second or 0)
end

local function current()
    local seconds = toSeconds(anchor.hour, anchor.minute)
    if not anchor.frozen then
        seconds += math.min(59, math.floor((GetGameTimer() - anchor.at) / anchor.ms * 60))
    end
    return seconds % 86400
end

function QClientClock.time()
    return anchor.hour, anchor.minute
end

local function apply(clock)
    if not clock then return end
    local before = current()
    anchor = { hour = clock.hour, minute = clock.minute, at = GetGameTimer(), ms = clock.ms or 5000, frozen = clock.frozen == true }
    local after = current()
    local gap = (after - before) % 86400
    -- A jump of more than two minutes (admin set the time) rolls forward over 3 s instead of snapping.
    if not clock.jump and gap > 120 and gap < 86400 - 120 then
        transition = { from = before, to = before + gap, started = GetGameTimer(), duration = 3000 }
    else
        transition = nil
    end
end

apply(GlobalState[QWeather.keys.clock])

AddStateBagChangeHandler(QWeather.keys.clock, 'global', function(_, _, value)
    apply(value)
end)

CreateThread(function()
    while true do
        local seconds
        if QClient.paused then
            seconds = toSeconds(QClient.pausedHour or 20, 0)
        elseif transition then
            local t = (GetGameTimer() - transition.started) / transition.duration
            if t >= 1 then
                transition = nil
                seconds = current()
            else
                seconds = math.floor(transition.from + (transition.to - transition.from) * t) % 86400
            end
        else
            seconds = current()
        end
        NetworkOverrideClockTime(seconds // 3600, (seconds % 3600) // 60, seconds % 60)
        Wait(0)
    end
end)
