-- ============================================================
-- Camada de retrocompatibilidade — client
-- ============================================================
-- Espelha a API client-side que o Renewed-Weathersync expunha, pra resources
-- que disparavam esses eventos/exports não quebrarem.
--
-- Polaridade do sync (importante): no mri o `cd_easytime:PauseSync(true)` PAUSA
-- o sync (mostra clima estático), e `PauseSync(false)` retoma. Mapeamos os
-- eventos do qb/vSync seguindo a semântica do Renewed:
--   DisableSync  → para de seguir o server → PauseSync(true)
--   EnableSync   → volta a seguir          → PauseSync(false)
--   vSync:toggle(true)  = sync ligado       → PauseSync(false)
-- ============================================================

-- Export cd_easytime:GetWeather() no client (mesma shape do Renewed).
AddEventHandler('__cfx_export_cd_easytime_GetWeather', function(setCB)
    setCB(function()
        if not self then return {} end
        return {
            weather = self.weather,
            blackout = self.blackout,
            freeze = self.freeze,
        }
    end)
end)

RegisterNetEvent('qb-weathersync:client:EnableSync', function()
    TriggerEvent('cd_easytime:PauseSync', false)
end)

RegisterNetEvent('qb-weathersync:client:DisableSync', function()
    TriggerEvent('cd_easytime:PauseSync', true)
end)

RegisterNetEvent('vSync:toggle', function(boolean)
    TriggerEvent('cd_easytime:PauseSync', not boolean)
end)

-- Sugestões de chat pros comandos de compat (registrados em server/compat.lua).
AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    TriggerEvent('chat:addSuggestion', '/time', 'Define a hora', {
        { name = 'hora', help = '0-23' },
        { name = 'minuto', help = '0-59 (opcional)' },
    })
    TriggerEvent('chat:addSuggestion', '/noon', 'Define a hora para meio-dia (12:00)')
    TriggerEvent('chat:addSuggestion', '/morning', 'Define a hora para manhã (09:00)')
    TriggerEvent('chat:addSuggestion', '/evening', 'Define a hora para o fim de tarde (18:00)')
    TriggerEvent('chat:addSuggestion', '/night', 'Define a hora para a noite (23:00)')
    TriggerEvent('chat:addSuggestion', '/weather', 'Define o clima', {
        { name = 'tipo', help = 'CLEAR, RAIN, THUNDER, SNOW, ...' },
    })
    TriggerEvent('chat:addSuggestion', '/timescale', 'Velocidade do tempo', {
        { name = 'ms', help = 'ms por minuto de jogo (mín 1000)' },
    })
    TriggerEvent('chat:addSuggestion', '/freezetime', 'Congela/descongela o tempo', {
        { name = 'estado', help = '1 = congela, 0 = descongela' },
    })
end)
