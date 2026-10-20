local T = Config.temperature
local wet = { BLIZZARD = true, SNOW = true, SNOW_HALLOWEEN = true }
for weather in pairs(QWeather.rainy) do wet[weather] = true end
local cached = 20.0

-- The server's base (weather on screen, hour, month) refined for this player: zone, height, wind, water, interior.
local function localCelsius()
    local weather = QClientWeather.target()
    local hour, minute = QClientClock.time()
    local gs = GlobalState.temperature
    local celsius = (T.base[weather] or T.fallback)
        + math.cos(((hour + minute / 60 - T.peakHour) / 24) * 2 * math.pi) * T.dayNightAmplitude
        + (T.monthOffset[gs and gs.month or 0] or 0)
        + QClientZones.tempMod()

    local ped = cache.ped
    if GetInteriorFromEntity(ped) ~= 0 then return T.interior end
    celsius -= (GetEntityCoords(ped).z - T.altitude.seaLevelZ) / 1000.0 * T.altitude.lapsePerKm
    if wet[weather] then celsius -= GetWindSpeed() * T.windChillFactor end
    if IsEntityInWater(ped) then celsius += T.waterMod end
    return celsius
end

local function toUnit(celsius)
    if QClient.settings().temperature.unit == 'F' then return celsius * 9 / 5 + 32 end
    return celsius
end

CreateThread(function()
    while true do
        cached = localCelsius()
        Wait(T.updateInterval)
    end
end)

function GetTemperature()
    return math.floor(toUnit(cached) * 10 + 0.5) / 10
end

function GetTemperatureData()
    return {
        value = GetTemperature(),
        celsius = math.floor(cached * 10 + 0.5) / 10,
        unit = QClient.settings().temperature.unit,
    }
end
