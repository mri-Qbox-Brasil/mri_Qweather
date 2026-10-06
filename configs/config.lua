Config = {}
function L(cd) if Locales[Config.Language][cd] then return Locales[Config.Language][cd] else print('Locale is nil ('..cd..')') end end


--███████╗██████╗  █████╗ ███╗   ███╗███████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
--██╔════╝██╔══██╗██╔══██╗████╗ ████║██╔════╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
--█████╗  ██████╔╝███████║██╔████╔██║█████╗  ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
--██╔══╝  ██╔══██╗██╔══██║██║╚██╔╝██║██╔══╝  ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
--██║     ██║  ██║██║  ██║██║ ╚═╝ ██║███████╗╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
--╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝


--WHAT DOES 'auto_detect' DO?
--The 'auto_detect' feature automatically identifies the resources you have and applies the appropriate default settings accordingly.

Config.Framework = 'auto_detect' --[ 'auto_detect' / 'other' ]
--If you select 'auto_detect', only ESX, QBCore and Qbox frameworks will be detected. Use 'other' for custom frameworks.

Config.Notification = 'auto_detect' --[ 'auto_detect' / 'other' ]
--If you select 'auto_detect', only ESX, QBCore, Qbox, cd_notifications, okokNotify, ps-ui and ox_lib notifications will be detected. Use 'other' for custom notification resources.

Config.Language = 'EN' --[ 'EN' / 'FR' / 'ES' ]
--You can add your own locales to Locales.lua, but be sure to update the Config.Language to match it.

Config.FrameworkTriggers = {
    esx = { --If you have modified the default event names in the es_extended resource, change them here.
        resource_name = 'es_extended',
        main = 'esx:getSharedObject',
        load = 'esx:playerLoaded'
    },
    qbcore = { --If you have modified the default event names in the qb-core resource, change them here.
        resource_name = 'qb-core',
        main = 'QBCore:GetObject',
        load = 'QBCore:Client:OnPlayerLoaded'
    },
    qbox = { --If you have modified the default event names in the qbx-core resource, change them here.
        resource_name = 'qbx_core'
    }
}

Config.Permissions = { --Define which players can access the cd_easytime features.
    Framework = { --Ignore this section if you're not using a framework.
        ['esx'] = {'superadmin', 'admin', 'mod', },
        ['qbcore'] = {'god', 'admin', },
        ['qbox'] = {'god', 'admin', },
    },

    Identifiers = {
        ENABLE = false, --Allow players with specific identifiers to access cd_easytime?
        identifier_list = {'steam:xxxxx', 'license:xxxxx', 'fivem:xxxxx', } --List player identifiers (Steam, license, or FiveM ID).
    },

    AcePerms = { 
        ENABLE = false, --Allow players with specific ACE permissions to access cd_easytime?
        aceperms_list = {'command', 'easytime.staff', } --Ensure your ACE permissions are set up in server.cfg.
    },

    Discord = { --This feature requires the Badger Discord API resource.
        ENABLE = false, --Allow players with specific Discord roles to access cd_easytime?
        discord_list = {'xxxxx', 'xxxxx', } --Enter the role IDs from your Discord (see https://www.itgeared.com/how-to-get-role-id-on-discord).
    }
}


--██╗███╗   ███╗██████╗  ██████╗ ██████╗ ████████╗ █████╗ ███╗   ██╗████████╗
--██║████╗ ████║██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝
--██║██╔████╔██║██████╔╝██║   ██║██████╔╝   ██║   ███████║██╔██╗ ██║   ██║   
--██║██║╚██╔╝██║██╔═══╝ ██║   ██║██╔══██╗   ██║   ██╔══██║██║╚██╗██║   ██║   
--██║██║ ╚═╝ ██║██║     ╚██████╔╝██║  ██║   ██║   ██║  ██║██║ ╚████║   ██║   
--╚═╝╚═╝     ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝


Config.Debug = false -- Set to true to enable debug prints for troubleshooting.
Config.APIKey = 'CHANGE_ME' --You need this when using real time or weather. Get your free API key from https://openweathermap.org/api.


--███╗   ███╗ █████╗ ██╗███╗   ██╗
--████╗ ████║██╔══██╗██║████╗  ██║
--██╔████╔██║███████║██║██╔██╗ ██║
--██║╚██╔╝██║██╔══██║██║██║╚██╗██║
--██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
--╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝


Config.Command = 'clima' --The command for staff to open the UI.
Config.ConsolePrints = true --Do you want the console to print the weather changes?
Config.VehicleBlackoutEffect = false --Do you want the lights on vehicles to be turned off during blackouts?

Config.TsunamiWarning = {
    ENABLE = true, --Do you want to enable the tsunami warning countdown just before a server restart?
    time = 2 --(in minutes) How long the tsunami warning should last. Read the docs for more info.
}

Config.Weather = {
    METHOD = 'game', --Choose between 'game' (GTA weather) or 'real' (real-world weather).

    GameWeather = { --If you chose 'game', you have the following configurable options:
        dynamic_weather_time = 10, --How often (in minutes) should the weather change?
        rain_chance = 20, --Chance of rain (0-100%) if the rain WeatherGroup is randomly selected.
        thunder_chance = 20, --Chance of thunder during rain (0-100%).
        fog_chance = 20, --Chance of fog (0-100%) if the fog WeatherGroup is randomly selected.
        snow_chance = 5, --Chance of snow (0-100%) if the rain WeatherGroup is randomly selected.
        WeatherGroups = { --Different weather groups to cycle through.
            [1] = {'CLEAR', 'CLOUDS','EXTRASUNNY', 'OVERCAST'},--Clear weather
            [2] = {'CLEARING', 'RAIN', 'THUNDER'},--Rainy weather
            [3] = {'SMOG', 'FOGGY'},--Foggy weather
            [4] = {'SNOWLIGHT', 'SNOW', 'BLIZZARD', 'XMAS'}--Snowy weather
        }
    },

    RealWeather = { --If you chose 'real', you have the following configurable options:
        city = 'London', --The city from which you want to fetch the weather, e.g., London, Miami, Dubai, or Paris.
        weather_check = 30, --How often (in minutes) to check for weather changes.
        weather_types = { ['CLEAR'] = {802,302,312,314,500,520,521}, ['CLOUDS'] = {803}, ['EXTRASUNNY'] = {800,801}, ['OVERCAST'] = {804}, ['CLEARING'] = {300,301,310,311,313,321}, ['RAIN'] = {501,502,503,504,511,522,531}, ['THUNDER'] = {200,201,202,210,211,212,221,230,231,232}, ['SMOG'] = {701,711,721,731,771}, ['FOGGY'] = {741,751,761,762,781}, ['SNOWLIGHT'] = {611,615,616}, ['SNOW'] = {600,620}, ['BLIZZARD'] = {612,613,620,621,622}, ['XMAS'] = {601,602} } --Weather types and their codes (do not change this).
    },

    --█████╗ Sistema de FILA DE PREVISÃO (portado do Renewed-Weathersync) █████╗--
    -- Quando ENABLE = true e o método é 'game', uma fila de previsão pré-gerada
    -- controla o clima dinâmico (substitui o ciclo por WeatherGroups). O toggle
    -- "dinâmico" do painel liga/desliga a fila. Editável pela seção "Previsão".
    Forecast = {
        ENABLE = true, --Usar a fila de previsão em vez do ciclo dinâmico por grupos?

        serverDuration = 14, --Quantas horas o servidor roda antes do restart (dimensiona a fila).
        weatherCycletimer = 30, --Minutos de cada evento do staticWeather.
        timeBetweenRain = 480, --Minutos mínimos entre eventos de chuva.
        rainAfterRestart = 480, --Minutos após o restart antes da primeira chuva.
        decemberSnow = false, --Se true, só neva (XMAS) durante dezembro.

        useStaticWeather = true, --Inserir eventos avulsos por chance individual.
        staticWeather = {
            ['BLIZZARD'] = 0.0, ['CLEAR'] = 0.1, ['CLEARING'] = 0.1, ['CLOUDS'] = 0.0,
            ['EXTRASUNNY'] = 0.4, ['FOGGY'] = 0.0, ['NEUTRAL'] = 0.0, ['OVERCAST'] = 0.0,
            ['RAIN'] = 0.0, ['SMOG'] = 0.0, ['SNOW'] = 0.0, ['SNOWLIGHT'] = 0.0,
            ['THUNDER'] = 0.1, ['XMAS'] = 0.0,
        },

        useWeatherSequences = true, --Usar sequências de clima (com vento/neve por evento).
        -- 'time' aceita número fixo (ex: 14) OU range {min, max} (ex: {3, 10}).
        -- O range é sorteado a cada geração da fila (varia entre restarts).
        weatherSequences = {
            { -- Ensolarado
                probability = 0.1,
                events = {
                    { weather = 'SMOG', time = {3, 10}, windSpeed = 0.05 },
                    { weather = 'CLEAR', time = {5, 10}, windSpeed = 0.1 },
                    { weather = 'EXTRASUNNY', time = {3, 10}, windSpeed = 0.05 },
                },
            },
            { -- Nublado
                probability = 0.10,
                events = {
                    { weather = 'OVERCAST', time = {5, 10}, windSpeed = 0.1 },
                    { weather = 'CLOUDS', time = {3, 10}, windSpeed = 0.05 },
                },
            },
            { -- Nevando
                probability = 0.3,
                month = 12,
                events = {
                    { weather = 'OVERCAST', time = {5, 10}, windSpeed = 0.0 },
                    { weather = 'SNOWLIGHT', time = {5, 10}, windSpeed = 0.1 },
                    { weather = 'SNOW', time = {3, 7}, windSpeed = 0.3 },
                    { weather = 'SNOWLIGHT', time = {5, 10}, windSpeed = 0.1 },
                    { weather = 'OVERCAST', time = {3, 7}, windSpeed = 0.0 },
                    { weather = 'CLOUDS', time = {3, 7}, windSpeed = 0.0 },
                },
            },
            { -- Tempestade de neve
                probability = 0.30,
                windDirection = 120.0,
                month = 12,
                events = {
                    { weather = 'OVERCAST', time = {5, 10}, windSpeed = 0.5 },
                    { weather = 'SNOWLIGHT', time = {3, 7}, windSpeed = 1.0 },
                    { weather = 'SNOW', time = {3, 7}, windSpeed = 1.0 },
                    { weather = 'SNOW', time = {5, 10}, windSpeed = 1.0, hasSnow = true },
                    { weather = 'BLIZZARD', time = 14, windSpeed = 3.0, hasSnow = true },
                    { weather = 'SNOW', time = 15, windSpeed = 2.0, hasSnow = true },
                    { weather = 'SNOWLIGHT', time = 20, windSpeed = 1.0, hasSnow = true },
                    { weather = 'OVERCAST', time = 15, windSpeed = 0.5, hasSnow = true },
                    { weather = 'CLOUDS', time = 15, windSpeed = 0.5, hasSnow = true },
                    { weather = 'CLEAR', time = 15, windSpeed = 0.5, hasSnow = true },
                    { weather = 'EXTRASUNNY', time = 15, windSpeed = 0.5 },
                },
            },
            { -- Aguaceiro
                probability = 0.1,
                windDirection = 240.0,
                events = {
                    { weather = 'CLOUDS', time = {3, 7}, windSpeed = 0.5 },
                    { weather = 'OVERCAST', time = {3, 7}, windSpeed = 1.0 },
                    { weather = 'RAIN', time = {5, 10}, windSpeed = 2.0 },
                    { weather = 'CLEARING', time = {3, 7}, windSpeed = 1.0 },
                    { weather = 'CLOUDS', time = {5, 10}, windSpeed = 0.5 },
                    { weather = 'EXTRASUNNY', time = {5, 10}, windSpeed = 0.0 },
                },
            },
            { -- Temporal
                probability = 0.10,
                windDirection = 280.0,
                events = {
                    { weather = 'CLOUDS', time = {3, 7}, windSpeed = 0.5 },
                    { weather = 'OVERCAST', time = {3, 7}, windSpeed = 1.0 },
                    { weather = 'RAIN', time = {5, 10}, windSpeed = 3.5 },
                    { weather = 'CLEARING', time = {3, 7}, windSpeed = 1.5 },
                    { weather = 'CLOUDS', time = {3, 7}, windSpeed = 0.5 },
                },
            },
            { -- Tempestade leve
                probability = 0.10,
                windDirection = 120.0,
                events = {
                    { weather = 'CLOUDS', time = {3, 7}, windSpeed = 0.5 },
                    { weather = 'RAIN', time = {3, 7}, windSpeed = 1.0 },
                    { weather = 'THUNDER', time = {3, 7}, windSpeed = 3.0 },
                    { weather = 'RAIN', time = {5, 10}, windSpeed = 2.0 },
                    { weather = 'CLEARING', time = {3, 7}, windSpeed = 1.0 },
                    { weather = 'EXTRASUNNY', time = {5, 10}, windSpeed = 0.5 },
                },
            },
            { -- Tempestade forte
                windDirection = 180.0,
                probability = 0.10,
                events = {
                    { weather = 'OVERCAST', time = {3, 7}, windSpeed = 4.0 },
                    { weather = 'RAIN', time = {3, 7}, windSpeed = 8.0 },
                    { weather = 'THUNDER', time = {3, 7}, windSpeed = 12.0 },
                    { weather = 'RAIN', time = {3, 7}, windSpeed = 12.0 },
                    { weather = 'THUNDER', time = {3, 7}, windSpeed = 12.0 },
                    { weather = 'CLEARING', time = {3, 7}, windSpeed = 3.0 },
                    { weather = 'EXTRASUNNY', time = {3, 7}, windSpeed = 0.0 },
                },
            },
        },
    }
}

Config.Time = {
    METHOD = 'game', --Choose between 'game' (GTA time) or 'real' (real-world time).

    GameTime = { --If you chose 'game', you have the following configurable options:
        time_cycle_speed = 5, --Velocidade do DIA: segundos reais por minuto de jogo. 1 = dia de 24min, 2 = 48min (padrão GTA), 5 = 120min.
        night_cycle_speed = 5, --Velocidade da NOITE: segundos reais por minuto de jogo (durante a janela noturna). Igual ao dia por padrão.
        night_start = 22, --Hora em que a escala NOTURNA começa.
        night_end = 6, --Hora em que a escala noturna termina (volta pra escala do dia).
    },

    RealTime = { --If you chose 'real', you have the following configurable options:
        city = 'London', --The city from which you want to fetch the time, e.g., London, Miami, Dubai, or Paris.
        manual_UTC_offset = 0, --Manually set the time zone offset (in hours) if automatic detection is inaccurate. For example, use 3 for UTC+3 or -2 for UTC-2. Set to nil to disable this feature.
        transition_speed = 10 --The speed at which time transitions occur to ensure smooth minute-to-minute changes (in seconds).
    }
}


--████████╗███████╗███╗   ███╗██████╗ ███████╗██████╗  █████╗ ████████╗██╗   ██╗██████╗  █████╗
--╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██╔══██╗
--   ██║   █████╗  ██╔████╔██║██████╔╝█████╗  ██████╔╝███████║   ██║   ██║   ██║██████╔╝███████║
--   ██║   ██╔══╝  ██║╚██╔╝██║██╔═══╝ ██╔══╝  ██╔══██╗██╔══██║   ██║   ██║   ██║██╔══██╗██╔══██║
--   ██║   ███████╗██║ ╚═╝ ██║██║     ███████╗██║  ██║██║  ██║   ██║   ╚██████╔╝██║  ██║██║  ██║
--   ╚═╝   ╚══════╝╚═╝     ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- Temperatura simulada (o GTA não tem temperatura nativa). O SERVER calcula uma
-- base global (clima + hora + mês) e publica em GlobalState.temperature + export.
-- O CLIENT refina por jogador (altitude, água, wind chill, modificador de zona).
-- É export-only: este resource não aplica efeitos — só expõe o valor.

Config.Temperature = {
    ENABLE = true,
    unit = 'C', -- 'C' (Celsius) ou 'F' (Fahrenheit) — afeta o valor retornado nos exports.

    -- Temperatura base (°C, ao meio-dia) por tipo de clima.
    base = {
        EXTRASUNNY = 32, CLEAR = 26, CLOUDS = 22, OVERCAST = 18,
        SMOG = 20, FOGGY = 14, CLEARING = 17, RAIN = 15, THUNDER = 14,
        SNOWLIGHT = 1, SNOW = -2, BLIZZARD = -8, XMAS = -3, NEUTRAL = 20,
    },
    fallback = 20, -- usado quando o clima atual não está na tabela 'base'.

    -- Curva diária senoidal: quanto a temperatura sobe/desce ao longo do dia.
    dayNightAmplitude = 6, -- °C entre o pico e o vale.
    peakHour = 15,         -- hora mais quente (o vale fica ~12h depois).

    -- Offset sazonal por mês (1-12), somado à base. Meses ausentes = 0.
    monthOffset = { [12] = -6, [1] = -7, [2] = -6, [6] = 3, [7] = 5, [8] = 5 },

    -- Refinos aplicados no CLIENT (por jogador):
    altitude  = { ENABLE = true, lapsePerKm = 6.5, seaLevelZ = 0.0 }, -- -6.5°C a cada 1000m de 'z' acima do nível.
    windChill = { ENABLE = true, factor = 0.7 }, -- °C a menos por unidade de windSpeed (só com chuva/vento).
    waterMod  = -4,   -- °C a menos quando dentro d'água.
    interior  = 21,   -- temp fixa (°C) em interiores; use nil pra manter a externa.

    updateInterval = 2000, -- ms entre recálculos client-side.
}


--███████╗ ██████╗ ███╗   ██╗ █████╗ ███████╗
--╚══███╔╝██╔═══██╗████╗  ██║██╔══██╗██╔════╝
--  ███╔╝ ██║   ██║██╔██╗ ██║███████║███████╗
-- ███╔╝  ██║   ██║██║╚██╗██║██╔══██║╚════██║
--███████╗╚██████╔╝██║ ╚████║██║  ██║███████║
--╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
-- Clima por zonas (camada CLIENT). O clima do GTA é global na tela, então "zona"
-- = quando o jogador entra numa região, o client sobrepõe o clima da zona ao
-- sync global do server (o forecast continua sendo o clima "padrão" fora delas).
--
-- Regras (rule):
--   { mode = 'fixed', weather = 'SNOW' }            -> força esse clima na zona.
--   { mode = 'bias', allow = {...}, fallback='...'} -> se o clima global está em
--        'allow', mostra ele; senão troca pelo 'fallback' (default = allow[1]).
--        Determinístico (todos os players na zona veem o mesmo), sem sync extra.
-- tempMod: °C somados à temperatura dentro da zona.

Config.Zones = {
    ENABLE = true,
    transitionSpeed = 25.0, -- suavidade da transição ao entrar/sair de uma zona.
    checkInterval = 1500,   -- ms entre checagens da posição do jogador.

    -- Zonas NATIVAS do GTA (GET_NAME_OF_ZONE). Cobertura de mapa inteiro, barata.
    -- Códigos: veja https://docs.fivem.net/natives/?_0x27040C25 (ex: 'MTCHIL').
    natives = {
        ['MTCHIL'] = { rule = { mode = 'bias', allow = {'OVERCAST','CLOUDS','SNOWLIGHT','SNOW','FOGGY'}, fallback = 'SNOWLIGHT' }, tempMod = -8 }, -- Mount Chiliad
        -- ['DESRT']  = { rule = { mode = 'bias', allow = {'EXTRASUNNY','CLEAR','CLOUDS'}, fallback = 'EXTRASUNNY' }, tempMod = 6 }, -- Grand Senora
        -- ['BEACH']  = { rule = { mode = 'bias', allow = {'EXTRASUNNY','CLEAR','CLOUDS','OVERCAST','RAIN','THUNDER'}, fallback = 'CLEAR' }, tempMod = 2 }, -- praia (nunca neva)
    },

    -- Zonas CUSTOM (prioridade sobre as nativas; maior 'priority' vence).
    -- shape = 'circle' { coords = vec3, radius } ou 'poly' { points = { vec2, ... } }.
    -- ⚠️ Isto é só o SEED inicial. Em runtime as zonas custom são editadas
    -- in-game pela aba "Zonas" do painel e salvas em data/zones.json (que passa a
    -- ser a fonte de verdade). Zonas circle são editáveis no jogo; poly só aqui.
    custom = {
        -- { id = 'ilha_gelada', shape = 'circle', coords = vec3(3500.0, 3700.0, 30.0), radius = 250.0,
        --   priority = 10, rule = { mode = 'fixed', weather = 'BLIZZARD' }, tempMod = -14 },
        -- { id = 'vale_deserto', shape = 'poly', points = { vec2(2400.0,3200.0), vec2(2900.0,3200.0), vec2(2900.0,3600.0), vec2(2400.0,3600.0) },
        --   priority = 5, rule = { mode = 'bias', allow = {'EXTRASUNNY','CLEAR'}, fallback = 'EXTRASUNNY' }, tempMod = 8 },
    },
}


-- █████╗ ██╗   ██╗████████╗ ██████╗     ██████╗ ███████╗████████╗███████╗ ██████╗████████╗
--██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗    ██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝
--███████║██║   ██║   ██║   ██║   ██║    ██║  ██║█████╗     ██║   █████╗  ██║        ██║   
--██╔══██║██║   ██║   ██║   ██║   ██║    ██║  ██║██╔══╝     ██║   ██╔══╝  ██║        ██║   
--██║  ██║╚██████╔╝   ██║   ╚██████╔╝    ██████╔╝███████╗   ██║   ███████╗╚██████╗   ██║   
--╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝     ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝ ╚═════╝   ╚═╝   
        

-----DO NOT TOUCH ANYTHING BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING.-----
if Config.Framework == 'auto_detect' then
    if GetResourceState(Config.FrameworkTriggers.esx.resource_name) == 'started' then
        Config.Framework = 'esx'
    elseif GetResourceState(Config.FrameworkTriggers.qbcore.resource_name) == 'started' then
        Config.Framework = 'qbcore'
    elseif GetResourceState(Config.FrameworkTriggers.qbox.resource_name) == 'started' then
        Config.Framework = 'qbox'
    end
end
if Config.Framework == 'esx' or Config.Framework == 'qbcore' or Config.Framework == 'qbox' then
    for c, d in pairs(Config.FrameworkTriggers[Config.Framework]) do
        Config.FrameworkTriggers[c] = d
    end
    Config.FrameworkTriggers.esx, Config.FrameworkTriggers.qbcore, Config.FrameworkTriggers.qbox = nil, nil, nil
    Config.Permissions.Framework.ENABLE = true
else
    Config.Permissions.Framework.ENABLE = false
end

if GetResourceState('Badger_Discord_API') ~= 'started' then
    if Config.Permissions.Discord.ENABLE and Config.Debug then
        print('^1Error: Badger_Discord_API_not_started.^0')
    end
    Config.Permissions.Discord.ENABLE = false
end

if Config.Notification == 'auto_detect' then
    if GetResourceState('cd_notifications') == 'started' then
        Config.Notification = 'cd_notifications'
    elseif GetResourceState('okokNotify') == 'started' then
        Config.Notification = 'okokNotify'
    elseif GetResourceState('ps-ui') == 'started' then
        Config.Notification = 'ps-ui'
    elseif GetResourceState('ox_lib') == 'started' then
        Config.Notification = 'ox_lib'
    else
        if Config.Framework == 'esx' or Config.Framework == 'qbcore' or Config.Framework == 'qbox' then
            Config.Notification = Config.Framework
        else
            Config.Notification = 'chat'
        end
    end
end

Config.Time.GameTime.time_cycle_speed = math.ceil(Config.Time.GameTime.time_cycle_speed) --this value can not be a float.
-----DO NOT TOUCH ANYTHING ABOVE THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING.-----