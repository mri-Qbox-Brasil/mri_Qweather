QReal = {}

local last = nil

-- OpenWeatherMap condition code (openweathermap.org/weather-conditions) to the closest GTA weather.
local function toGta(code)
    if code >= 200 and code < 300 then return 'THUNDER' end
    if code >= 300 and code < 400 then return 'CLEARING' end
    if code == 500 or code == 520 then return 'CLEARING' end
    if code >= 500 and code < 600 then return 'RAIN' end
    if code == 600 or code == 615 or code == 620 then return 'SNOWLIGHT' end
    if code == 602 or code == 622 then return 'BLIZZARD' end
    if code >= 600 and code < 700 then return 'SNOW' end
    if code == 701 or code == 741 then return 'FOGGY' end
    if code >= 700 and code < 800 then return 'SMOG' end
    if code == 800 then return 'EXTRASUNNY' end
    if code == 801 then return 'CLEAR' end
    if code == 802 or code == 803 then return 'CLOUDS' end
    return 'OVERCAST'
end

-- Blocking call (yields): returns the reading, or nil when the city or key is missing or wrong.
function QReal.fetch()
    local cfg = QSettings.get().real
    if cfg.city == '' or cfg.apiKey == '' then return nil end
    local function encode(text)
        return (text:gsub('[^%w%-_.~]', function(c) return ('%%%02X'):format(c:byte()) end))
    end
    local url = ('https://api.openweathermap.org/data/2.5/weather?q=%s&appid=%s&units=metric'):format(encode(cfg.city), encode(cfg.apiKey))
    local p = promise.new()
    PerformHttpRequest(url, function(status, body)
        local ok, data = pcall(json.decode, body or '')
        if status ~= 200 or not ok or type(data) ~= 'table' or type(data.weather) ~= 'table' or not data.weather[1] then
            print(('^3[%s] clima real: a cidade ou a chave não foram aceitas (HTTP %s)^0'):format(QWeather.resource, status))
            return p:resolve(nil)
        end
        local condition = data.weather[1]
        p:resolve({
            weather = toGta(tonumber(condition.id) or 800),
            description = condition.description,
            city = data.name,
            country = data.sys and data.sys.country,
            temperature = data.main and data.main.temp,
        })
    end, 'GET')
    last = Citizen.Await(p) or last
    return last
end

function QReal.last()
    return last
end

local function apply()
    local reading = QReal.fetch()
    if reading and reading.weather ~= QState.get().weather then QState.setWeather(reading.weather) end
end

CreateThread(function()
    while true do
        if QState.get().realWeather then
            apply()
            Wait(QSettings.get().real.checkMinutes * 60000)
        else
            Wait(5000)
        end
    end
end)

AddEventHandler('mri_Qweather:server:flagChanged', function(flag, value)
    if flag == 'realWeather' and value then CreateThread(apply) end
end)
