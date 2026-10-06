-- ============================================================
-- Temperatura — server (base global)
-- ============================================================
-- Calcula uma temperatura-base a partir do clima atual (self.weather), da hora
-- (self.hours/mins) e do mês, publica em GlobalState.temperature (°C, arredondado)
-- e expõe via export. É a temperatura "global" do servidor — o client refina por
-- jogador (altitude/água/vento/zona) em client/temperature.lua.
--
-- `self` e Config são globais (server.lua / config.lua). Este arquivo carrega
-- depois de server.lua (ordem alfabética: server < temperature).
-- ============================================================

local T = Config.Temperature

if not T or not T.ENABLE then
    -- Exports precisam existir mesmo desligado (evita erro em quem consome).
    function GetTemperature() return nil end
    return
end

-- Base (°C) só do clima + hora + mês. Compartilhada com o client (mesma fórmula).
local function baseTemperature(weather, hour, month)
    local base = T.base[weather] or T.fallback

    -- Curva diária: cos() = +amplitude no peakHour, -amplitude ~12h depois.
    local phase = ((hour - (T.peakHour or 15)) / 24) * 2 * math.pi
    base = base + math.cos(phase) * (T.dayNightAmplitude or 0)

    -- Offset sazonal.
    base = base + (T.monthOffset[month] or 0)

    return base
end

-- Converte pra unidade configurada (o GlobalState e o export usam a mesma).
local function toUnit(celsius)
    if T.unit == 'F' then
        return celsius * 9 / 5 + 32
    end
    return celsius
end

local function currentCelsius()
    local weather = (self and self.weather) or 'CLEAR'
    local hour = ((self and self.hours) or 12) + (((self and self.mins) or 0) / 60)
    local month = tonumber(os.date('%m'))
    return baseTemperature(weather, hour, month)
end

-- Export server: temperatura-base global na unidade configurada (número).
function GetTemperature()
    return toUnit(currentCelsius())
end

-- Publica no GlobalState pra consumo barato por outros resources.
-- GlobalState.temperature = { value = <unidade>, celsius = <°C>, unit = 'C'|'F' }
CreateThread(function()
    while not (self and self.weather) do Wait(500) end
    local last, lastMonth
    while true do
        local celsius = currentCelsius()
        local value = math.floor(toUnit(celsius) * 10 + 0.5) / 10 -- 1 casa decimal
        local month = tonumber(os.date('%m'))
        -- Publica o mês junto: o client não tem a lib `os`, então lê daqui pra
        -- aplicar o offset sazonal (client/temperature.lua).
        if value ~= last or month ~= lastMonth then
            last, lastMonth = value, month
            GlobalState.temperature = { value = value, celsius = celsius, unit = T.unit, month = month }
        end
        Wait(5000)
    end
end)
