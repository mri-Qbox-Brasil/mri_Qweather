fx_version 'cerulean'
game 'gta5'
author 'discord.gg/codesign'
description 'Codesign Weather & Time Managment'
version '2.0.5'
lua54 'yes'

shared_scripts {
    'configs/locales.lua',
    'configs/config.lua',
    '@ox_lib/init.lua', --⚠️PLEASE READ⚠️; Uncomment this line if you use 'ox_lib'.⚠️
    '@qbx_core/modules/lib.lua', --⚠️PLEASE READ⚠️; Uncomment this line if you use 'qbx_core'.⚠️
}

client_scripts {
    'configs/client_customise_me.lua',
    'client/*.lua',
    '@qbx_core/modules/playerdata.lua', --⚠️PLEASE READ⚠️; Uncomment this line if you use 'qbx_core'.⚠️
}

server_scripts {
    'configs/server_customise_me.lua',
    'server/*.lua'
}

ui_page 'web/build/index.html'
files {
    -- NUI em React (mri-ui-kit). Build: `pnpm -C web build`.
    'web/build/index.html',
    'web/build/**/*',
}

exports {
    'GetWeather',
    'GetAllData',
    'GetPauseSyncState'
}

server_exports {
    'GetWeather',
    'GetAllData',
    'GetRealData',
    'SetTime',
    'SetWeather'
}

escrow_ignore {
    'client/client.lua',
    'configs/client_customise_me.lua',
    'configs/config.lua',
    'server/server.lua',
    'server/version_check.lua',
}

provide 'vSync'
provide 'qb-weathersync'
provide 'qbx_weathersync'