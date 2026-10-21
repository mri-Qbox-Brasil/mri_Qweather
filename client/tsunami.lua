QClientTsunami = {}

local running = nil
local CAYO = vec2(4700.0, -5150.0)

function QClientTsunami.active()
    return running ~= nil
end

-- Sea quads of water/flood.xml (a grid over the whole map, level 0) are the ones that rise.
local function seaQuads()
    local list = {}
    for i = 0, GetWaterQuadCount() - 1 do
        local ok, level = GetWaterQuadLevel(i)
        if ok and math.abs(level) < 0.5 then list[#list + 1] = i end
    end
    return list
end

local function setLevel(quads, level)
    for i = 1, #quads do SetWaterQuadLevel(quads[i], level + 0.0) end
end

-- The sea rises from the start of the warning and takes `rise` seconds (0 = all of it) to get to full height.
local function flood(id, data, startedAt, total)
    local height = tonumber(data.flood) or 0
    if height <= 0 then return end
    -- Cayo Perico runs its own water there; LoadWaterFromPath would wipe it.
    if #(GetEntityCoords(cache.ped).xy - CAYO) < 2000.0 then return end
    local rise = tonumber(data.rise) or 0
    local duration = rise > 0 and math.min(rise, total) or total
    CreateThread(function()
        local quads
        while running == id do
            local progress = (GetGameTimer() - startedAt) / 1000 / duration
            if progress > 0 then
                if not quads then
                    LoadWaterFromPath(QWeather.resource, 'water/flood.xml')
                    quads = seaQuads()
                    running.quads = quads
                end
                local level = height * math.min(progress, 1.0)
                running.level = level
                setLevel(quads, level)
            end
            Wait(100)
        end
    end)
end

local function start(data)
    local id = {}
    running = id
    local total = tonumber(data.seconds) or 120
    local left = math.max(0, math.min(total, (tonumber(data.endsAt) or 0) - GetCloudTimeAsInt()))
    local elapsed = total - left
    local startedAt = GetGameTimer() - elapsed * 1000
    local storm = GetGameBuildNumber() >= 3258 and 'RAIN_HALLOWEEN' or 'HALLOWEEN'
    -- The storm takes the first quarter to build up; joining later shows it already built.
    QClientWeather.force(storm, math.max(0, total / 4 - elapsed))
    SetDeepOceanScaler(3.0)
    if elapsed < 5 then
        lib.notify({ title = locale('tsunami_title'), description = locale(data.restart and 'tsunami_restart' or 'tsunami_alert', math.max(1, math.ceil(left / 60))), type = 'warning', duration = 15000 })
    end
    -- Halfway through, lights go out and the siren plays until the end.
    SetTimeout(math.max(0, math.floor((total / 2 - elapsed) * 1000)), function()
        if running ~= id then return end
        SetArtificialLightsState(true)
        SetArtificialLightsStateAffectsVehicles(true)
        SendNUIMessage({ action = 'siren' })
    end)
    flood(id, data, startedAt, total)
end

-- The water goes down over a few seconds before the game's own water comes back.
local function recede(quads, from)
    CreateThread(function()
        for step = 20, 0, -1 do
            if running then return end
            setLevel(quads, from * step / 20)
            Wait(250)
        end
        if not running then ResetWater() end
    end)
end

local function stop()
    if not running then return end
    local last = running
    running = nil
    SendNUIMessage({ action = 'sirenStop' })
    ResetDeepOceanScaler()
    if last.quads then recede(last.quads, last.level or 0) end
    QClientWeather.restoreBlackout()
    QClientWeather.refresh()
end

local function apply(value)
    if type(value) == 'table' then start(value) else stop() end
end

AddStateBagChangeHandler(QWeather.keys.tsunami, 'global', function(_, _, value)
    apply(value)
end)

AddEventHandler('onClientResourceStart', function(name)
    if name == QWeather.resource and type(GlobalState[QWeather.keys.tsunami]) == 'table' then
        apply(GlobalState[QWeather.keys.tsunami])
    end
end)

AddEventHandler('onClientResourceStop', function(name)
    if name == QWeather.resource and running and running.quads then ResetWater() end
end)
