-- Integração com o painel admin central mri_Qadmin. Registra a aba "Clima" como
-- plugin (iframe embedded). Se o mri_Qadmin não estiver rodando, o pcall protege
-- e a UI continua acessível normalmente via /clima. O shape do manifest espelha
-- web/src/plugin/types.ts (controle de drift manual).

local function registerPlugin()
    if GetResourceState('mri_Qadmin') ~= 'started' then return end
    local resource = GetCurrentResourceName()
    local ok, result = pcall(function()
        return exports['mri_Qadmin']:RegisterPlugin({
            id = 'weather',
            label = 'Clima',
            icon = 'cloud-sun',
            resource = resource,
            htmlPath = 'web/build/index.html',
            requiredPerms = { resource .. '.admin', 'command' },
            description = 'Controle de clima e hora do servidor',
        })
    end)
    if not ok or result == false then
        print(('[%s] Falha ao registrar plugin no mri_Qadmin: %s'):format(resource, tostring(result)))
    end
end

CreateThread(function()
    local deadline = GetGameTimer() + 10000
    while GetResourceState('mri_Qadmin') ~= 'started' and GetGameTimer() < deadline do
        Wait(200)
    end
    registerPlugin()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'mri_Qadmin' then
        Wait(500) -- aguarda os exports do Qadmin ficarem disponíveis
        registerPlugin()
    end
end)

-- Estado atual do clima/hora pro NUI embedded buscar (NUI callback 'getState' no
-- client.lua chama isto). Gateado por permissão — mesmo gate do /clima.
lib.callback.register('cd_easytime:server:getData', function(source)
    if not PermissionsCheck(source) then return false end
    return GetAllData()
end)
