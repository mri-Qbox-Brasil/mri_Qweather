-- ============================================================
-- Temperatura — client (localizada por jogador)
-- ============================================================
-- Pega a base (clima efetivo + hora + mês, mesma fórmula do server) e refina pra
-- ESTE jogador: modificador de zona, altitude, wind chill, água e interior.
-- Expõe via export. É export-only — nenhum efeito de jogo é aplicado aqui.
--
--   exports.mri_Qweather:GetTemperature()      -> número (na unidade do config)
--   exports.mri_Qweather:GetTemperatureData()  -> { value, celsius, unit }
--
-- `self` (client.lua), ZoneWeatherOverride/MRIZone (zones.lua) são globais.
-- ============================================================

local T = Config.Temperature

if not T or not T.ENABLE then
    function GetTemperature() return nil end
    function GetTemperatureData() return nil end
    return
end

-- Igual ao baseTemperature do server (clima + hora + mês).
local function baseTemperature(weather, hour, month)
    local base = T.base[weather] or T.fallback
    local phase = ((hour - (T.peakHour or 15)) / 24) * 2 * math.pi
    base = base + math.cos(phase) * (T.dayNightAmplitude or 0)
    base = base + (T.monthOffset[month] or 0)
    return base
end

local rainy = { RAIN = true, THUNDER = true, CLEARING = true, BLIZZARD = true, SNOW = true }

-- Temperatura localizada (°C) pra este jogador.
local function localCelsius()
    -- Clima efetivo = o que o jogador realmente vê (zona ou global).
    local weather = self.weather or 'CLEAR'
    if ZoneWeatherOverride then weather = ZoneWeatherOverride(weather) end

    local hour = (self.hours or 12) + ((self.mins or 0) / 60)
    -- O client não tem a lib `os`; o mês vem do server via statebag
    -- (server/temperature.lua publica em GlobalState.temperature.month).
    local gs = GlobalState.temperature
    local month = gs and gs.month or nil
    local celsius = baseTemperature(weather, hour, month)

    -- Modificador da zona atual.
    if MRIZone and MRIZone.tempMod then
        celsius = celsius + MRIZone.tempMod
    end

    local ped = PlayerPedId()

    -- Interior: temperatura ambiente fixa (curto-circuita os refinos externos).
    if T.interior ~= nil and GetInteriorFromEntity(ped) ~= 0 then
        return T.interior
    end

    -- Altitude: lapse rate (-lapsePerKm °C a cada 1000m acima do nível do mar).
    if T.altitude and T.altitude.ENABLE then
        local z = GetEntityCoords(ped).z
        local km = (z - (T.altitude.seaLevelZ or 0.0)) / 1000.0
        celsius = celsius - km * (T.altitude.lapsePerKm or 6.5)
    end

    -- Wind chill: só quando faz sentido (chuva/neve/vento).
    if T.windChill and T.windChill.ENABLE and rainy[weather] then
        celsius = celsius - GetWindSpeed() * (T.windChill.factor or 0.0)
    end

    -- Dentro d'água.
    if T.waterMod and IsEntityInWater(ped) then
        celsius = celsius + T.waterMod
    end

    return celsius
end

local function toUnit(celsius)
    if T.unit == 'F' then
        return celsius * 9 / 5 + 32
    end
    return celsius
end

-- Cache atualizado num intervalo (evita recalcular a cada chamada do export).
local cachedCelsius = 20.0

CreateThread(function()
    while not self.weather do Wait(500) end
    while true do
        cachedCelsius = localCelsius()
        Wait(T.updateInterval or 2000)
    end
end)

function GetTemperature()
    return math.floor(toUnit(cachedCelsius) * 10 + 0.5) / 10
end

function GetTemperatureData()
    return {
        value = GetTemperature(),
        celsius = math.floor(cachedCelsius * 10 + 0.5) / 10,
        unit = T.unit,
    }
end
