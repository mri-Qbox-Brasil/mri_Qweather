local function context()
    return {
        lang = GetConvar('ox:locale', 'en'),
        gameBuild = GetGameBuildNumber(),
        accentColor = GetConvar('mri:color', '#00E699'),
        backgroundColor = GetConvar('mri:backgroundColor', ''),
    }
end

local function withContext(state)
    if type(state) ~= 'table' then return state end
    for k, v in pairs(context()) do state[k] = v end
    return state
end

RegisterNetEvent('mri_Qweather:client:open', function(state)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', state = withContext(state) })
end)

RegisterNetEvent('mri_Qweather:client:theme', function()
    SendNUIMessage({ action = 'theme', theme = context() })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb(true)
end)

-- Every callback answers with fresh data: inside the mri_Qadmin iframe no SendNUIMessage arrives.
local function bridge(name, fn)
    RegisterNUICallback(name, function(data, cb)
        cb(fn(type(data) == 'table' and data or {}) or false)
    end)
end

bridge('getState', function()
    return withContext(lib.callback.await('mri_Qweather:server:getState', false))
end)

bridge('control', function(data)
    local result = lib.callback.await('mri_Qweather:server:control', false, data.action, data.value)
    if result then withContext(result.state) end
    return result
end)

bridge('getSettings', function()
    return lib.callback.await('mri_Qweather:server:getSettings', false)
end)

bridge('saveSettings', function(data)
    return lib.callback.await('mri_Qweather:server:saveSettings', false, data.section, data.values)
end)

bridge('getForecast', function()
    return lib.callback.await('mri_Qweather:server:getForecast', false)
end)

bridge('forecast', function(data)
    return lib.callback.await('mri_Qweather:server:forecast', false, data.action, data.index, data.value)
end)

bridge('getEnvironment', function()
    return {
        temperature = GetTemperatureData(),
        zone = GetZone(),
        weather = QClient.weather(),
        effective = QClientWeather.target(),
    }
end)

bridge('getZones', function()
    local data = lib.callback.await('mri_Qweather:server:getZones', false)
    if not data then return false end
    -- Region names only exist on the client (text labels).
    data.labels = {}
    for code in pairs(data.natives or {}) do data.labels[code] = GetLabelText(code) end
    return data
end)

bridge('addZone', function(data)
    return lib.callback.await('mri_Qweather:server:addZone', false, data)
end)

bridge('updateZone', function(data)
    return lib.callback.await('mri_Qweather:server:updateZone', false, data.id, data)
end)

bridge('removeZone', function(data)
    return lib.callback.await('mri_Qweather:server:removeZone', false, data.id)
end)

bridge('setNativeZone', function(data)
    return lib.callback.await('mri_Qweather:server:setNativeZone', false, data.code, data)
end)

bridge('removeNativeZone', function(data)
    return lib.callback.await('mri_Qweather:server:removeNativeZone', false, data.code)
end)

bridge('getPlayerCoords', function()
    local c = GetEntityCoords(cache.ped)
    return { x = c.x, y = c.y, z = c.z, heading = GetEntityHeading(cache.ped) }
end)

bridge('getPlayerZoneCode', function()
    local c = GetEntityCoords(cache.ped)
    local code = GetNameOfZone(c.x, c.y, c.z)
    return { code = code, label = code and GetLabelText(code) or nil }
end)

RegisterNUICallback('teleport', function(coords, cb)
    cb(true)
    if type(coords) ~= 'table' or not tonumber(coords.x) or not tonumber(coords.y) then return end
    if not lib.callback.await('mri_Qweather:server:canManage', false) then return end
    local x, y = coords.x + 0.0, coords.y + 0.0
    local z = tonumber(coords.z) and coords.z + 0.0 or 0.0
    local ped = cache.ped
    -- A map click has no height and far ground has no collision yet: hold the ped up there until it loads.
    FreezeEntityPosition(ped, true)
    SetPedCoordsKeepVehicle(ped, x, y, z > 0.0 and z or 500.0)
    for _ = 1, 40 do
        RequestCollisionAtCoord(x, y, z)
        local found, ground = GetGroundZFor_3dCoord(x, y, 1000.0, false)
        if found then z = ground break end
        Wait(50)
    end
    SetPedCoordsKeepVehicle(ped, x, y, z)
    FreezeEntityPosition(ped, false)
end)
