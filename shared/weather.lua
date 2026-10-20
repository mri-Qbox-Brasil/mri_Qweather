QWeather = QWeather or {}

QWeather.resource = GetCurrentResourceName()

-- Weathers an admin, a zone or the forecast may pick. The halloween ones need game build 3258.
QWeather.types = {
    'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'OVERCAST', 'SMOG', 'FOGGY', 'CLEARING', 'RAIN', 'THUNDER',
    'SNOWLIGHT', 'SNOW', 'BLIZZARD', 'XMAS', 'NEUTRAL', 'HALLOWEEN', 'RAIN_HALLOWEEN', 'SNOW_HALLOWEEN',
}

local valid = {}
for i = 1, #QWeather.types do valid[QWeather.types[i]] = true end

-- Weathers with rain in weather.xml (CLEARING and NEUTRAL are a light drizzle).
QWeather.rainy = { CLEARING = true, NEUTRAL = true, RAIN = true, THUNDER = true, HALLOWEEN = true, RAIN_HALLOWEEN = true }
-- Only these have snow on the ground in GTA; SNOW and BLIZZARD only fall, so trails there would look painted on.
QWeather.snowGround = { XMAS = true, SNOW_HALLOWEEN = true }

function QWeather.isValid(weather)
    return type(weather) == 'string' and valid[weather] == true
end

-- State bag keys shared by server and client.
QWeather.keys = {
    weather = 'mri_Qweather:weather',
    clock = 'mri_Qweather:clock',
    blackout = 'mri_Qweather:blackout',
    tsunami = 'mri_Qweather:tsunami',
    settings = 'mri_Qweather:settings',
    zones = 'mri_zones',
    natives = 'mri_zone_natives',
}

-- Real milliseconds per game minute at a given hour, from the day and night lengths of the settings.
function QWeather.msPerMinute(hour, time)
    local nightStart, nightEnd = time.nightStart, time.nightEnd
    local nightHours = (nightEnd - nightStart) % 24
    local isNight
    if nightHours == 0 then
        isNight = false
    elseif nightStart < nightEnd then
        isNight = hour >= nightStart and hour < nightEnd
    else
        isNight = hour >= nightStart or hour < nightEnd
    end
    local gameMinutes = (isNight and nightHours or 24 - nightHours) * 60
    local realMinutes = isNight and time.nightMinutes or time.dayMinutes
    return math.max(250, math.floor(realMinutes * 60000 / math.max(gameMinutes, 1)))
end
