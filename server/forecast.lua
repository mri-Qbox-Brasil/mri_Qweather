-- ============================================================
-- Fila de previsão de clima (portado do Renewed-Weathersync)
-- ============================================================
-- Gera no boot uma fila de eventos de clima (weatherList) cobrindo as horas de
-- uptime do servidor, a partir de Config.Weather.Forecast (sequências por
-- probabilidade + climas avulsos), respeitando as regras de espaçamento de
-- chuva / pós-restart / mês. Uma thread anda a fila minuto a minuto e aplica o
-- clima atual. Substitui o ciclo dinâmico por WeatherGroups quando ENABLE=true.
--
-- `self`, PermissionsCheck e Config são globais (server.lua / customise / config).
-- ============================================================

local resource_name = GetCurrentResourceName()
local FC = Config.Weather.Forecast

if not FC or not FC.ENABLE then return end

local rainFilter = { RAIN = true, THUNDER = true }

-- Lista atual (upvalue compartilhado por runner e callbacks).
local forecast = {}
local active = false

-- ─────────────────────────────────────────────────────────────
-- Validação de clima (mesma vocabulário do SetWeather).
-- ─────────────────────────────────────────────────────────────
local function isValidWeather(weather)
    if type(weather) ~= 'string' then return false end
    for _, group in pairs(Config.Weather.GameWeather.WeatherGroups) do
        for _, w in ipairs(group) do
            if w == weather then return true end
        end
    end
    for w in pairs(Config.Weather.RealWeather.weather_types) do
        if w == weather then return true end
    end
    return false
end

-- ─────────────────────────────────────────────────────────────
-- Builder da fila (porta o weatherbuilder do Renewed). Roda dentro de uma
-- thread (usa Wait(0) pra não travar). Retorna um array de eventos.
-- ─────────────────────────────────────────────────────────────
local function buildForecast()
    local currentMonth = tonumber(os.date('%m'))
    local cycleTimer = FC.weatherCycletimer
    local weatherList = {}

    if FC.decemberSnow and currentMonth == 12 then
        return { { weather = 'XMAS', time = 86400, windSpeed = 0.0, windDirection = 0.0, hasSnow = true } }
    end

    local function containsRain(events)
        for i = 1, #events do
            if rainFilter[events[i].weather] then return true end
        end
        return false
    end

    local minutesLeft = FC.serverDuration * 60
    local minutesSinceRain = FC.timeBetweenRain + 1
    local timeBeforeRain = FC.rainAfterRestart

    local guard = 0
    while true do
        guard = guard + 1

        if FC.useWeatherSequences then
            for i = 1, #FC.weatherSequences do
                local seq = FC.weatherSequences[i]
                local hasRain = containsRain(seq.events)
                local allowed = seq.probability >= math.random()
                    and (not seq.month or seq.month == currentMonth)
                    and (not hasRain or (timeBeforeRain <= 0 and minutesSinceRain >= FC.timeBetweenRain))

                if allowed then
                    local timeUsed = 0
                    for j = 1, #seq.events do
                        local ev = seq.events[j]
                        weatherList[#weatherList + 1] = {
                            weather = ev.weather,
                            time = ev.time,
                            windSpeed = ev.windSpeed,
                            -- windDirection da sequência aplicado por evento
                            -- (no Renewed isso era ignorado por bug).
                            windDirection = ev.windDirection or seq.windDirection,
                            hasSnow = ev.hasSnow,
                        }
                        timeUsed = timeUsed + ev.time
                    end
                    minutesSinceRain = hasRain and 0 or (minutesSinceRain + timeUsed)
                    timeBeforeRain = (not hasRain) and (timeBeforeRain - timeUsed) or timeBeforeRain
                    minutesLeft = minutesLeft - timeUsed
                end
            end
        end

        if FC.useStaticWeather then
            local count = #weatherList
            for weather, chance in pairs(FC.staticWeather) do
                local hasRain = rainFilter[weather]
                local allowed = chance >= math.random()
                    and (not hasRain or (timeBeforeRain <= 0 and minutesSinceRain >= FC.timeBetweenRain))

                -- evita repetir o mesmo clima mais de 1x nos últimos 5 eventos
                if allowed and count > 5 then
                    local rep = 0
                    for k = count - 5, count do
                        if weatherList[k] and weatherList[k].weather == weather then
                            rep = rep + 1
                            if rep > 1 then allowed = false break end
                        end
                    end
                end

                if allowed then
                    count = count + 1
                    weatherList[count] = { weather = weather, time = cycleTimer }
                    minutesSinceRain = hasRain and 0 or (minutesSinceRain + cycleTimer)
                    timeBeforeRain = (not hasRain) and (timeBeforeRain - cycleTimer) or timeBeforeRain
                    minutesLeft = minutesLeft - cycleTimer
                end
            end
        end

        if minutesLeft <= 0 or guard > 2000 then break end
        Wait(0)
    end

    -- nunca retorna vazio
    if not weatherList[1] then
        weatherList[1] = { weather = (self and self.weather) or 'CLEAR', time = cycleTimer }
    end

    return weatherList
end

-- ─────────────────────────────────────────────────────────────
-- Aplica o clima de um evento da fila (transição suave + vento + neve).
-- ─────────────────────────────────────────────────────────────
local function applyEvent(event)
    if not event then return end
    self.weather = event.weather
    TriggerClientEvent('cd_easytime:SyncWeather', -1, {
        weather = event.weather,
        instantweather = false,
        windSpeed = event.windSpeed,
        windDirection = event.windDirection,
        hasSnow = event.hasSnow,
    })
    if Config.ConsolePrints then
        print(('^3[%s] - Previsão: clima -> %s (%s min)^0'):format(resource_name, event.weather, event.time))
    end
end

-- ─────────────────────────────────────────────────────────────
-- Runner: anda a fila enquanto o forecast está ativo (método game + dinâmico).
-- ─────────────────────────────────────────────────────────────
CreateThread(function()
    while not (self and self.weather) do Wait(500) end
    forecast = buildForecast()
    print(('^2[%s] - Previsão gerada com %d eventos.^0'):format(resource_name, #forecast))

    while true do
        local shouldRun = self.weathermethod == 'game' and self.dynamic

        if shouldRun then
            if not active then
                -- acabou de ativar (dinâmico ligado): aplica o evento atual.
                active = true
                applyEvent(forecast[1])
            else
                local cur = forecast[1]
                if cur then
                    cur.time = cur.time - 1
                    if cur.time <= 0 then
                        table.remove(forecast, 1)
                        if not forecast[1] then forecast = buildForecast() end
                        applyEvent(forecast[1])
                    end
                else
                    forecast = buildForecast()
                    applyEvent(forecast[1])
                end
            end
            Wait(60000)
        else
            active = false
            Wait(1000)
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- Callbacks de gerenciamento (usados pela seção "Previsão" do painel).
-- Gateados pelo mesmo PermissionsCheck do /clima.
-- ─────────────────────────────────────────────────────────────

lib.callback.register('cd_easytime:server:getForecast', function(source)
    if not PermissionsCheck(source) then return false end
    -- cópia rasa pra NUI (não expõe a referência mutável)
    local out = {}
    for i = 1, #forecast do
        local e = forecast[i]
        out[i] = {
            weather = e.weather,
            time = e.time,
            windSpeed = e.windSpeed,
            windDirection = e.windDirection,
            hasSnow = e.hasSnow,
        }
    end
    return { enabled = (self.weathermethod == 'game' and self.dynamic) or false, events = out }
end)

lib.callback.register('cd_easytime:server:setForecastWeather', function(source, index, weather)
    if not PermissionsCheck(source) then return false end
    index = tonumber(index)
    if not index or not forecast[index] or not isValidWeather(weather) then return false end

    forecast[index].weather = weather
    -- se é o evento atual e o forecast está ativo, aplica na hora.
    if index == 1 and self.weathermethod == 'game' and self.dynamic then
        applyEvent(forecast[1])
    end
    return weather
end)

lib.callback.register('cd_easytime:server:setForecastTime', function(source, index, time)
    if not PermissionsCheck(source) then return false end
    index = tonumber(index)
    time = math.floor(tonumber(time) or 0)
    if not forecast[index] or time < 1 then return false end
    if time > 1440 then time = 1440 end

    forecast[index].time = time
    return time
end)

lib.callback.register('cd_easytime:server:removeForecastEvent', function(source, index)
    if not PermissionsCheck(source) then return false end
    index = tonumber(index)
    if not index or not forecast[index] then return false end

    table.remove(forecast, index)
    if not forecast[1] then forecast = buildForecast() end
    -- removeu o evento atual → aplica o novo da frente (se ativo).
    if index == 1 and self.weathermethod == 'game' and self.dynamic then
        applyEvent(forecast[1])
    end
    return true
end)
