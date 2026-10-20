fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mri_Qweather'
description 'Clima e hora sincronizados, com previsão, zonas de clima, temperatura e painel próprio'
author 'MRI Qbox'
version '3.0.2'
license 'MIT with Commons Clause'
repository 'https://github.com/mri-Qbox-Brasil/mri_Qweather'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/weather.lua',
}

client_scripts {
    'client/state.lua',
    'client/clock.lua',
    'client/weather.lua',
    'client/zones.lua',
    'client/temperature.lua',
    'client/tsunami.lua',
    'client/panel.lua',
    'client/compat.lua',
}

server_scripts {
    'server/settings.lua',
    'server/state.lua',
    'server/clock.lua',
    'server/real.lua',
    'server/forecast.lua',
    'server/tsunami.lua',
    'server/zones.lua',
    'server/temperature.lua',
    'server/panel.lua',
    'server/compat.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**/*',
    'locales/*.json',
}

exports {
    'GetWeather',
    'GetAllData',
    'GetPauseSyncState',
    'GetTemperature',
    'GetTemperatureData',
    'GetZone',
}

server_exports {
    'GetWeather',
    'GetAllData',
    'GetRealData',
    'SetTime',
    'SetWeather',
    'SetBlackout',
    'SetTimeFreeze',
    'SetDynamic',
    'SetTimeScale',
    'GetTemperature',
    'GetForecastQueue',
}

-- Answers for the weather scripts it replaces: server/compat.lua and client/compat.lua carry their exports and events.
provides {
    'vSync',
    'qb-weathersync',
    'qbx_weathersync',
    'cd_easytime',
    'Renewed-Weathersync',
}

dependency 'ox_lib'
