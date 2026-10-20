local T = Config.temperature

-- Same formula as the client (weather + hour + month); the client refines it per player.
local function baseCelsius(weather, hour, month)
    local base = T.base[weather] or T.fallback
    base += math.cos(((hour - T.peakHour) / 24) * 2 * math.pi) * T.dayNightAmplitude
    return base + (T.monthOffset[month] or 0)
end

local function toUnit(celsius)
    if QSettings.get().temperature.unit == 'F' then return celsius * 9 / 5 + 32 end
    return celsius
end

local function currentCelsius()
    local state = QState.get()
    return baseCelsius(state.weather, state.hour + state.minute / 60, tonumber(os.date('%m')))
end

function GetTemperature()
    return toUnit(currentCelsius())
end

-- GlobalState.temperature = { value, celsius, unit, month }; the client has no os lib, so the month rides along.
CreateThread(function()
    local last
    while true do
        local celsius = currentCelsius()
        local unit = QSettings.get().temperature.unit
        local value = math.floor(toUnit(celsius) * 10 + 0.5) / 10
        local month = tonumber(os.date('%m'))
        local key = ('%s|%s|%s'):format(value, unit, month)
        if key ~= last then
            last = key
            GlobalState.temperature = { value = value, celsius = celsius, unit = unit, month = month }
        end
        Wait(5000)
    end
end)
