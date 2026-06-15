-- Sistema de cores da suite MRI via convar global `mri:color` (destaque) e
-- `mri:backgroundColor` (fundo). Os clientes leem a convar replicada direto
-- (setr) na abertura da UI; aqui só propagamos MUDANÇAS em runtime, já que
-- convar-change não chega no client automaticamente.
--
-- Defina no server.cfg (use `setr` para replicar ao client):
--   setr mri:color "#00E699"
--   setr mri:backgroundColor ""   (vazio = tema padrão)

local HEX_PATTERN = '^#%x%x%x%x%x%x$'

local function isValidHex(value)
    return type(value) == 'string' and value:match(HEX_PATTERN) ~= nil
end

local function resolveAccentColor()
    local convar = GetConvar('mri:color', '')
    if isValidHex(convar) then
        return convar
    end
    return '#00E699'
end

AddConvarChangeListener('mri:color', function(name)
    if name ~= 'mri:color' then return end
    TriggerClientEvent('cd_easytime:client:accentColorChanged', -1, resolveAccentColor())
end)

AddConvarChangeListener('mri:backgroundColor', function(name)
    if name ~= 'mri:backgroundColor' then return end
    TriggerClientEvent('cd_easytime:client:backgroundColorChanged', -1, GetConvar('mri:backgroundColor', ''))
end)
