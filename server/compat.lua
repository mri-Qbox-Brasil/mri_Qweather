-- ============================================================
-- Camada de retrocompatibilidade — server
-- ============================================================
-- Antes o servidor rodava o Renewed-Weathersync, que expunha sua API sob os
-- namespaces `qb-weathersync` e `cd_easytime` (além de espelhar GlobalState).
-- Outros resources podem ter sido escritos contra essa API. Aqui replicamos a
-- mesma superfície (mesmos nomes de export, evento e GlobalState) mapeando pras
-- funções internas do mri_Qweather (fork do cd_easytime).
--
-- `self`, SetWeather, SetTime, SetBlackout, SetTimeFreeze e SetDynamic são
-- globais definidos em server/server.lua. Este arquivo carrega antes (ordem
-- alfabética), então só os referenciamos dentro de funções/threads — resolvidos
-- em runtime, quando server.lua já rodou.
-- ============================================================

-- Registra um export sob um namespace arbitrário (mesma técnica do Renewed),
-- funcionando mesmo sem `provide` do resource original.
local function exportHandler(namespace, name, fn)
    AddEventHandler(('__cfx_export_%s_%s'):format(namespace, name), function(setCB)
        setCB(fn)
    end)
end

-- ─────────────────────────────────────────────────────────────
-- Exports do qb-weathersync  →  exports['qb-weathersync']:<name>(...)
-- ─────────────────────────────────────────────────────────────

exportHandler('qb-weathersync', 'setWeather', function(weather)
    return SetWeather(weather)
end)

exportHandler('qb-weathersync', 'setTime', function(hour, minute)
    return SetTime(tonumber(hour), tonumber(minute) or 0)
end)

exportHandler('qb-weathersync', 'setBlackout', function(state)
    return SetBlackout(state and true or false)
end)

exportHandler('qb-weathersync', 'setTimeFreeze', function(state)
    return SetTimeFreeze(state and true or false)
end)

exportHandler('qb-weathersync', 'setDynamicWeather', function(state)
    return SetDynamic(state and true or false)
end)

exportHandler('qb-weathersync', 'getWeatherState', function()
    return self and self.weather
end)

exportHandler('qb-weathersync', 'getBlackoutState', function()
    return self and self.blackout or false
end)

exportHandler('qb-weathersync', 'getTimeFreezeState', function()
    return self and self.freeze or false
end)

exportHandler('qb-weathersync', 'getDynamicWeather', function()
    return self and self.dynamic or false
end)

exportHandler('qb-weathersync', 'getTime', function()
    if not self then return 0, 0 end
    return self.hours, self.mins
end)

-- Não tem equivalente direto; mantido pra não quebrar quem chama (como no Renewed).
exportHandler('qb-weathersync', 'nextWeatherStage', function()
    print('[mri_Qweather] export qb-weathersync:nextWeatherStage não é suportado.')
end)

-- ─────────────────────────────────────────────────────────────
-- Export do cd_easytime  →  exports['cd_easytime']:GetWeather()
-- (mesma shape do Renewed: { weather, blackout, freeze })
-- ─────────────────────────────────────────────────────────────

exportHandler('cd_easytime', 'GetWeather', function()
    if not self then return {} end
    return {
        weather = self.weather,
        blackout = self.blackout,
        freeze = self.freeze,
    }
end)

-- ─────────────────────────────────────────────────────────────
-- Eventos server do qb-weathersync (disparados pelo client, gateados por ACE,
-- igual ao Renewed).
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('qb-weathersync:server:setWeather', function(weather)
    if not IsPlayerAceAllowed(source, 'command.weather') then return end
    SetWeather(weather)
end)

RegisterNetEvent('qb-weathersync:server:setTime', function(hour, minute)
    if not IsPlayerAceAllowed(source, 'command.time') then return end
    SetTime(tonumber(hour), tonumber(minute) or 0)
end)

-- ─────────────────────────────────────────────────────────────
-- Espelho do GlobalState (statebags) — pra resources que liam o estado direto
-- do Renewed (GlobalState.weather/.currentTime/.timeScale/.freezeTime/.blackOut).
-- Statebags só replicam quando o valor muda; comparamos antes de escrever pra
-- não floodar a rede.
-- ─────────────────────────────────────────────────────────────

CreateThread(function()
    local last = {}

    while true do
        if self and self.weather then
            -- timeScale do Renewed = ms por minuto de jogo. No mri é o
            -- GameTimeInterval (global, mexido por /timescale).
            local timeScale = GameTimeInterval or ((Config.Time.GameTime.time_cycle_speed or 5) * 1000)

            if self.weather ~= last.weather then
                last.weather = self.weather
                GlobalState.weather = { weather = self.weather, time = 9999999 }
            end

            if self.hours ~= last.hours or self.mins ~= last.mins then
                last.hours, last.mins = self.hours, self.mins
                GlobalState.currentTime = { hour = self.hours, minute = self.mins }
            end

            local freeze = self.freeze and true or false
            if freeze ~= last.freeze then
                last.freeze = freeze
                GlobalState.freezeTime = freeze
            end

            local blackout = self.blackout and true or false
            if blackout ~= last.blackout then
                last.blackout = blackout
                GlobalState.blackOut = blackout
            end

            if timeScale ~= last.timeScale then
                last.timeScale = timeScale
                GlobalState.timeScale = timeScale
            end
        end
        Wait(1000)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- Comandos de texto que o Renewed expunha (/time, /noon, ...). Gateados pelo
-- mesmo PermissionsCheck do /clima. PermissionsCheck e Notification são globais
-- definidos em configs/server_customise_me.lua.
-- ─────────────────────────────────────────────────────────────

-- Registra um comando admin com a checagem de permissão padrão do mri.
local function adminCommand(name, handler)
    RegisterCommand(name, function(source, args, raw)
        if source ~= 0 and not PermissionsCheck(source) then
            Notification(source, 3, L('invalid_permissions'))
            return
        end
        handler(source, args, raw)
    end, false)
end

adminCommand('time', function(source, args)
    local hour = tonumber(args[1])
    local minute = tonumber(args[2]) or 0
    if not hour then
        Notification(source, 3, 'Uso: /time <hora> [minuto]')
        return
    end
    if SetTime(hour, minute) then
        Notification(source, 1, ('Hora definida para %02d:%02d'):format(hour, minute))
    else
        Notification(source, 3, 'Hora inválida (0-23 / 0-59).')
    end
end)

local timeShortcuts = {
    noon    = { 12, 0 },
    morning = { 9, 0 },
    evening = { 18, 0 },
    night   = { 23, 0 },
}
for name, t in pairs(timeShortcuts) do
    adminCommand(name, function(source)
        SetTime(t[1], t[2])
        Notification(source, 1, ('Hora definida para %02d:%02d'):format(t[1], t[2]))
    end)
end

adminCommand('weather', function(source, args)
    local weather = args[1] and string.upper(args[1])
    if not weather then
        Notification(source, 3, 'Uso: /weather <tipo> (ex: CLEAR, RAIN, THUNDER, SNOW)')
        return
    end
    if SetWeather(weather) then
        Notification(source, 1, 'Clima definido para '..weather)
    else
        Notification(source, 3, 'Tipo de clima inválido: '..weather)
    end
end)

adminCommand('timescale', function(source, args)
    local ms = tonumber(args[1])
    if not ms then
        Notification(source, 3, 'Uso: /timescale <ms por minuto de jogo> (mín 1000)')
        return
    end
    if SetTimeScale(ms) then
        Notification(source, 1, 'Timescale definido para '..math.floor(ms)..'ms/min.')
    else
        Notification(source, 3, 'Valor inválido (mínimo 1000ms).')
    end
end)

adminCommand('freezetime', function(source, args)
    local state = args[1] == '1' or args[1] == 'true'
    SetTimeFreeze(state)
    Notification(source, 1, state and 'Tempo congelado.' or 'Tempo descongelado.')
end)
