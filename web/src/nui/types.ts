// Tipos espelhados do objeto `values` que o client.lua envia/recebe.
// Fonte: html/js/script.js (objeto `values`) — NÃO mudar os nomes/casing,
// pois é o contrato com o Lua.

export type WeatherType =
  | 'CLEAR'
  | 'EXTRASUNNY'
  | 'CLOUDS'
  | 'OVERCAST'
  | 'RAIN'
  | 'CLEARING'
  | 'THUNDER'
  | 'SMOG'
  | 'FOGGY'
  | 'SNOW'
  | 'SNOWLIGHT'
  | 'BLIZZARD'
  | 'HALLOWEEN'
  | 'XMAS'
  | 'NEUTRAL'
  | 'RAIN_HALLOWEEN'
  | 'SNOW_HALLOWEEN'

export type Method = 'game' | 'real'

export interface RealInfo {
  weather: string
  weather_description: string
  country: string
  city: string
}

export interface EasytimeValues {
  hours: number
  mins: number
  weather: WeatherType
  dynamic: boolean
  blackout: boolean
  freeze: boolean
  instanttime: boolean
  instantweather: boolean
  tsunami: boolean
  realtime: boolean
  realweather: boolean
  game_build: number
  weathermethod: Method
  timemethod: Method
  original_weathermethod: Method
  original_timemethod: Method
  /** Escala do tempo: segundos reais por minuto de jogo (dia / noite). */
  dayscale: number
  nightscale: number
  /** Janela noturna (horas) — só pra UI converter escala ↔ minutos reais. */
  night_start: number
  night_end: number
  real_info: RealInfo
  /** Cor de destaque (convar mri:color). Injetada pelo client.lua. */
  accentColor?: string
  /** Cor de fundo (convar mri:backgroundColor). Injetada pelo client.lua. */
  backgroundColor?: string
}

/** Mensagem enviada pelo Lua via SendNUIMessage. */
export type NuiMessage =
  | { action: 'open'; values: EasytimeValues }
  | { action: 'close' }
  | { action: 'playsound' }
