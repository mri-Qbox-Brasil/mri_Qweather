-- ============================================================
-- Clima por zonas — client (camada de override)
-- ============================================================
-- O clima do GTA é global na tela; então "zona" = quando o jogador entra numa
-- região, sobrepomos localmente o clima da zona ao sync global do server. Detecção
-- híbrida: zonas CUSTOM (raio/polígono, por prioridade) vencem; senão cai na zona
-- NATIVA do GTA (GetNameOfZone).
--
-- Expõe 2 globais consumidos pelo resto do client:
--   ZoneWeatherOverride(globalWeather) -> clima efetivo (zona ou o global).
--   MRIZone = { id, tempMod }          -> lido por client/temperature.lua.
--
-- `self`, ChangeWeather e PauseSync são globais de client.lua (carrega antes).
-- ============================================================

MRIZone = { id = nil, tempMod = 0 }

local Z = Config.Zones

-- Sempre define o override (mesmo desligado) pra client.lua poder chamar sem guard.
if not Z or not Z.ENABLE then
    function ZoneWeatherOverride(globalWeather) return globalWeather end
    function GetZone() return nil end
    return
end

-- ─────────────────────────────────────────────────────────────
-- Resolução do clima efetivo a partir da regra da zona.
-- ─────────────────────────────────────────────────────────────
local function ruleWeather(rule, globalWeather)
    if not rule then return globalWeather end
    if rule.mode == 'fixed' then
        return rule.weather or globalWeather
    elseif rule.mode == 'bias' then
        local allow = rule.allow or {}
        for i = 1, #allow do
            if allow[i] == globalWeather then return globalWeather end
        end
        return rule.fallback or allow[1] or globalWeather
    end
    return globalWeather
end

-- ─────────────────────────────────────────────────────────────
-- Point-in-polygon (ray casting) no plano XY.
-- ─────────────────────────────────────────────────────────────
local function pointInPoly(px, py, points)
    local inside = false
    local n = #points
    local j = n
    for i = 1, n do
        local xi, yi = points[i].x, points[i].y
        local xj, yj = points[j].x, points[j].y
        if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / ((yj - yi) + 1e-9) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

-- Zonas custom vêm do server (GlobalState.mri_zones, editável in-game). Fallback
-- pro config caso o statebag ainda não tenha chegado.
local function getCustomZones()
    local synced = GlobalState.mri_zones
    if type(synced) == 'table' then return synced end
    return Z.custom
end

-- Idem pras nativas (GlobalState.mri_zone_natives).
local function getNativeZones()
    local synced = GlobalState.mri_zone_natives
    if type(synced) == 'table' then return synced end
    return Z.natives
end

-- Distância 2D² (XY) — ignora Z pra zonas de mapa (montanha, ilha) baterem
-- independente da altitude do jogador.
local function dist2XY(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

-- ─────────────────────────────────────────────────────────────
-- Zona atual: custom (maior prioridade) tem precedência sobre a nativa.
-- Retorna { id, name, rule, tempMod } ou nil.
-- ─────────────────────────────────────────────────────────────
local function resolveZone(coords)
    local best, bestPrio
    local list = getCustomZones()
    for i = 1, #list do
        local zone = list[i]
        local match = false
        if zone.shape == 'circle' and zone.coords then
            local r = zone.radius or 0.0
            match = dist2XY(coords.x, coords.y, zone.coords.x, zone.coords.y) <= r * r
        elseif zone.shape == 'poly' and zone.points then
            match = pointInPoly(coords.x, coords.y, zone.points)
        end
        if match then
            local prio = zone.priority or 0
            if not bestPrio or prio > bestPrio then
                best, bestPrio = zone, prio
            end
        end
    end
    if best then
        return { id = best.id, name = best.name, rule = best.rule, tempMod = best.tempMod or 0 }
    end

    local name = GetNameOfZone(coords.x, coords.y, coords.z)
    local native = name and getNativeZones()[name]
    if native then
        return { id = name, rule = native.rule, tempMod = native.tempMod or 0 }
    end
    return nil
end

-- Estado da zona ativa (upvalue lido pelos globais expostos).
local activeZone = nil

-- Clima efetivo pro sync global respeitar a zona (chamado por client.lua).
function ZoneWeatherOverride(globalWeather)
    if not activeZone or PauseSync.state then return globalWeather end
    return ruleWeather(activeZone.rule, globalWeather)
end

function GetZone()
    if not activeZone then return nil end
    return { id = activeZone.id, name = activeZone.name, tempMod = activeZone.tempMod }
end

-- ─────────────────────────────────────────────────────────────
-- Runner: detecta a zona e reaplica o clima quando o efetivo muda (entrar/sair
-- de zona, ou clima global mudar enquanto numa zona de bias).
-- ─────────────────────────────────────────────────────────────
CreateThread(function()
    local lastEffective
    while true do
        if not PauseSync.state and self.weather then
            local coords = GetEntityCoords(PlayerPedId())
            activeZone = resolveZone(coords)
            MRIZone = { id = activeZone and activeZone.id or nil, tempMod = activeZone and activeZone.tempMod or 0 }

            local effective = ZoneWeatherOverride(self.weather)
            if effective ~= lastEffective then
                lastEffective = effective
                ChangeWeather(effective, false, Z.transitionSpeed)
            end
        end
        Wait(Z.checkInterval)
    end
end)
