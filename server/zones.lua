-- ============================================================
-- Zonas de clima — server (persistência + sync + edição in-game)
-- ============================================================
-- Zonas CUSTOM (raio/polígono) E NATIVAS (por código do GTA) são estado de
-- runtime: carregadas de data/zones.json (seed = Config.Zones), publicadas em
-- GlobalState.mri_zones / GlobalState.mri_zone_natives, e TODAS editáveis pelo
-- painel (aba "Zonas") via callbacks gateados por PermissionsCheck. O config vira
-- só o seed inicial.
--
-- Formato do JSON: { custom = [ ... ], natives = { CODE = {rule, tempMod} } }.
-- (Migra o formato antigo, que era só o array de custom.)
--
-- Config e PermissionsCheck são globais (config.lua / server_customise_me.lua).
-- ============================================================

local resource = GetCurrentResourceName()
local Z = Config.Zones

if not Z or not Z.ENABLE then return end

local zones = {}   -- array de zonas custom
local natives = {} -- map código-do-GTA -> { rule, tempMod }

-- ─────────────────────────────────────────────────────────────
-- Vocabulário de clima válido (mesmo do forecast/SetWeather).
-- ─────────────────────────────────────────────────────────────
local function isValidWeather(w)
    if type(w) ~= 'string' then return false end
    for _, g in pairs(Config.Weather.GameWeather.WeatherGroups) do
        for _, x in ipairs(g) do if x == w then return true end end
    end
    for x in pairs(Config.Weather.RealWeather.weather_types) do
        if x == w then return true end
    end
    return false
end

local function validateRule(rule)
    if type(rule) ~= 'table' then return nil end
    if rule.mode == 'fixed' then
        if not isValidWeather(rule.weather) then return nil end
        return { mode = 'fixed', weather = rule.weather }
    elseif rule.mode == 'bias' then
        local allow = {}
        if type(rule.allow) == 'table' then
            for _, w in ipairs(rule.allow) do
                if isValidWeather(w) then allow[#allow + 1] = w end
            end
        end
        if #allow == 0 then return nil end
        local fallback = isValidWeather(rule.fallback) and rule.fallback or allow[1]
        return { mode = 'bias', allow = allow, fallback = fallback }
    end
    return nil
end

-- ─────────────────────────────────────────────────────────────
-- Persistência + sync.
-- ─────────────────────────────────────────────────────────────
local function sync()
    GlobalState.mri_zones = zones
    GlobalState.mri_zone_natives = natives
end

local function save()
    SaveResourceFile(resource, 'data/zones.json', json.encode({ custom = zones, natives = natives }), -1)
end

local function seedCustom()
    local out = {}
    for i = 1, #Z.custom do
        local z = Z.custom[i]
        out[i] = {
            id = z.id, name = z.name, shape = z.shape, radius = z.radius,
            coords = z.coords and { x = z.coords.x + 0.0, y = z.coords.y + 0.0, z = z.coords.z + 0.0 } or nil,
            points = z.points, priority = z.priority or 0, rule = z.rule, tempMod = z.tempMod or 0,
        }
    end
    return out
end

local function seedNatives()
    local out = {}
    for code, entry in pairs(Z.natives or {}) do
        out[code] = { rule = entry.rule, tempMod = entry.tempMod or 0 }
    end
    return out
end

local function load()
    local raw = LoadResourceFile(resource, 'data/zones.json')
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            if decoded.custom or decoded.natives then
                zones = decoded.custom or {}
                natives = decoded.natives or {}
            else
                -- formato antigo: array só de custom. Natives ainda não persistiam.
                zones = decoded
                natives = seedNatives()
            end
            return
        end
        print(('^3[%s] - data/zones.json corrompido, usando o seed do config.^0'):format(resource))
    end
    zones = seedCustom()
    natives = seedNatives()
    save() -- cria o arquivo no primeiro boot
end

CreateThread(function()
    load()
    sync()
    local nCount = 0
    for _ in pairs(natives) do nCount = nCount + 1 end
    print(('^2[%s] - %d zona(s) custom + %d nativa(s) carregada(s).^0'):format(resource, #zones, nCount))
end)

-- ─────────────────────────────────────────────────────────────
-- Helpers de mutação (custom).
-- ─────────────────────────────────────────────────────────────
local function findIndex(id)
    for i = 1, #zones do if zones[i].id == id then return i end end
end

local function genId(name)
    local base = tostring(name or 'zona'):lower():gsub('%s+', '_'):gsub('[^%w_]', '')
    if base == '' then base = 'zona' end
    local id, n = base, 1
    while findIndex(id) do n = n + 1; id = base .. '_' .. n end
    return id
end

-- Valida e normaliza uma zona custom vinda do painel. Só circle é editável in-game.
local function sanitizeZone(data, existingId)
    if type(data) ~= 'table' then return nil, 'dados inválidos' end
    local rule = validateRule(data.rule)
    if not rule then return nil, 'regra inválida' end
    local c = data.coords
    if type(c) ~= 'table' or type(c.x) ~= 'number' or type(c.y) ~= 'number' then
        return nil, 'coordenadas inválidas'
    end
    local radius = tonumber(data.radius)
    if not radius or radius < 5.0 then return nil, 'raio inválido (mín 5)' end

    return {
        id = existingId or genId(data.name or data.id),
        name = type(data.name) == 'string' and data.name ~= '' and data.name or nil,
        shape = 'circle',
        coords = { x = c.x + 0.0, y = c.y + 0.0, z = (tonumber(c.z) or 0.0) + 0.0 },
        radius = radius + 0.0,
        priority = math.floor(tonumber(data.priority) or 0),
        tempMod = tonumber(data.tempMod) or 0,
        rule = rule,
    }
end

-- ─────────────────────────────────────────────────────────────
-- Callbacks do painel. Gateados pelo mesmo PermissionsCheck.
-- ─────────────────────────────────────────────────────────────
lib.callback.register('cd_easytime:server:getZones', function(source)
    if not PermissionsCheck(source) then return false end
    return { custom = zones, natives = natives }
end)

-- Custom ─────────────────────────────────────────────────────
lib.callback.register('cd_easytime:server:addZone', function(source, data)
    if not PermissionsCheck(source) then return false end
    local zone, err = sanitizeZone(data)
    if not zone then return false, err end
    zones[#zones + 1] = zone
    save(); sync()
    return zone.id
end)

lib.callback.register('cd_easytime:server:updateZone', function(source, id, data)
    if not PermissionsCheck(source) then return false end
    local idx = findIndex(id)
    if not idx then return false, 'zona não encontrada' end
    local zone, err = sanitizeZone(data, id)
    if not zone then return false, err end
    zones[idx] = zone
    save(); sync()
    return true
end)

lib.callback.register('cd_easytime:server:removeZone', function(source, id)
    if not PermissionsCheck(source) then return false end
    local idx = findIndex(id)
    if not idx then return false end
    table.remove(zones, idx)
    save(); sync()
    return true
end)

-- Nativas ────────────────────────────────────────────────────
lib.callback.register('cd_easytime:server:setNativeZone', function(source, code, data)
    if not PermissionsCheck(source) then return false end
    if type(code) ~= 'string' or code == '' then return false, 'código inválido' end
    local rule = validateRule(data and data.rule)
    if not rule then return false, 'regra inválida' end
    natives[code] = { rule = rule, tempMod = tonumber(data.tempMod) or 0 }
    save(); sync()
    return true
end)

lib.callback.register('cd_easytime:server:removeNativeZone', function(source, code)
    if not PermissionsCheck(source) then return false end
    if not natives[code] then return false end
    natives[code] = nil
    save(); sync()
    return true
end)
