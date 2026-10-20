QClientZones = {}

local keys = QWeather.keys
local activeZone = nil

local function ruleWeather(rule, cityWeather)
    if not rule then return cityWeather end
    if rule.mode == 'fixed' then return rule.weather or cityWeather end
    if rule.mode == 'bias' then
        local allow = rule.allow or {}
        for i = 1, #allow do
            if allow[i] == cityWeather then return cityWeather end
        end
        return rule.fallback or allow[1] or cityWeather
    end
    return cityWeather
end

local function pointInPoly(px, py, points)
    local inside, j = false, #points
    for i = 1, #points do
        local xi, yi, xj, yj = points[i].x, points[i].y, points[j].x, points[j].y
        if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / ((yj - yi) + 1e-9) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function enabled()
    return QClient.settings().zones.enabled == true
end

-- Drawn areas win over GTA regions; among areas the higher priority wins. Height is ignored on purpose.
local function resolve(coords)
    local best
    local custom = GlobalState[keys.zones] or Config.zones.custom
    for i = 1, #custom do
        local zone = custom[i]
        local inside = false
        if zone.shape == 'circle' and zone.coords then
            local dx, dy, r = coords.x - zone.coords.x, coords.y - zone.coords.y, zone.radius or 0.0
            inside = dx * dx + dy * dy <= r * r
        elseif zone.shape == 'poly' and zone.points then
            inside = pointInPoly(coords.x, coords.y, zone.points)
        end
        if inside and (not best or (zone.priority or 0) > (best.priority or 0)) then best = zone end
    end
    if best then return { id = best.id, name = best.name, rule = best.rule, tempMod = best.tempMod or 0 } end

    local code = GetNameOfZone(coords.x, coords.y, coords.z)
    local native = code and (GlobalState[keys.natives] or Config.zones.natives)[code]
    if native then return { id = code, rule = native.rule, tempMod = native.tempMod or 0 } end
end

function QClientZones.override(cityWeather)
    if not activeZone or not enabled() then return cityWeather end
    return ruleWeather(activeZone.rule, cityWeather)
end

function QClientZones.tempMod()
    return enabled() and activeZone and activeZone.tempMod or 0
end

function GetZone()
    if not activeZone or not enabled() then return nil end
    local name = activeZone.name
    if not name then
        local label = GetLabelText(activeZone.id)
        if label ~= 'NULL' then name = label end
    end
    return { id = activeZone.id, name = name, tempMod = activeZone.tempMod }
end

CreateThread(function()
    while true do
        if not QClient.paused then
            activeZone = resolve(GetEntityCoords(cache.ped))
            local target = QClientWeather.target()
            if target ~= QClientWeather.shown() then QClientWeather.refresh(QClient.settings().zones.transition) end
        end
        Wait(Config.zones.checkInterval)
    end
end)
