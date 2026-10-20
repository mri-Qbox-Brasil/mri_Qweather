QClock = {}

local nextTick = 0

-- Restarts the wait for the next game minute (after a time change, a freeze or a new day length).
function QClock.reset()
    nextTick = GetGameTimer() + QWeather.msPerMinute(QState.get().hour, QSettings.get().time)
end

local function realClock()
    local offset = QSettings.get().time.utcOffset
    local now = os.date('!*t', os.time() + offset * 3600)
    return now.hour, now.min
end

CreateThread(function()
    QClock.reset()
    while true do
        Wait(250)
        local state = QState.get()
        if state.realTime then
            local hour, minute = realClock()
            if hour ~= state.hour or minute ~= state.minute then QState.setTime(hour, minute, false) end
        elseif not state.freeze and GetGameTimer() >= nextTick then
            QState.tick()
            QClock.reset()
        end
    end
end)

AddEventHandler('mri_Qweather:server:flagChanged', function(flag, value)
    if flag == 'freeze' or flag == 'realTime' then QClock.reset() end
    if flag == 'realTime' and value then
        local hour, minute = realClock()
        QState.setTime(hour, minute, true)
    end
end)

AddEventHandler('mri_Qweather:server:settingsChanged', function(section)
    if section ~= 'time' then return end
    QClock.reset()
    QState.republishClock()
end)
