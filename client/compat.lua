-- Client exports of this resource and the names other weather scripts used.

function GetWeather()
    local hour, minute = QClientClock.time()
    return { weather = QClient.weather(), hours = hour, mins = minute, blackout = GlobalState[QWeather.keys.blackout] == true }
end

GetAllData = GetWeather

AddEventHandler('__cfx_export_cd_easytime_GetWeather', function(setCB)
    setCB(GetWeather)
end)

AddEventHandler('onClientResourceStart', function(name)
    if name ~= QWeather.resource then return end
    TriggerEvent('chat:addSuggestion', '/' .. Config.command, locale('chat_suggestion'))
    TriggerEvent('chat:addSuggestion', '/time', locale('suggest_time'), {
        { name = locale('suggest_hour'), help = '0-23' },
        { name = locale('suggest_minute'), help = locale('suggest_minute_help') },
    })
    TriggerEvent('chat:addSuggestion', '/morning', locale('suggest_morning'))
    TriggerEvent('chat:addSuggestion', '/noon', locale('suggest_noon'))
    TriggerEvent('chat:addSuggestion', '/evening', locale('suggest_evening'))
    TriggerEvent('chat:addSuggestion', '/night', locale('suggest_night'))
    TriggerEvent('chat:addSuggestion', '/weather', locale('suggest_weather'), {
        { name = locale('suggest_type'), help = 'CLEAR, RAIN, THUNDER, SNOW, ...' },
    })
    TriggerEvent('chat:addSuggestion', '/timescale', locale('suggest_timescale'), {
        { name = 'ms', help = locale('suggest_timescale_help') },
    })
    TriggerEvent('chat:addSuggestion', '/freezetime', locale('suggest_freezetime'), {
        { name = locale('suggest_state'), help = locale('suggest_state_help') },
    })
end)
