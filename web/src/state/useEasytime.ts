import { useCallback, useMemo, useRef, useState } from 'react'
import { fetchNui } from '@/nui/fetchNui'
import { useNuiEvent } from '@/nui/useNuiEvent'
import { convertTime, numToTime, timeToSlider } from '@/lib/time'
import type { EasytimeValues, Method, WeatherType } from '@/nui/types'

const DEFAULT_VALUES: EasytimeValues = {
  hours: 8,
  mins: 0,
  weather: 'CLEAR',
  dynamic: false,
  blackout: false,
  freeze: false,
  instanttime: false,
  instantweather: false,
  tsunami: false,
  realtime: false,
  realweather: false,
  game_build: 0,
  weathermethod: 'game',
  timemethod: 'game',
  original_weathermethod: 'game',
  original_timemethod: 'game',
  real_info: { weather: '', weather_description: '', country: '', city: '' },
}

const NEW_WEATHER_MIN_BUILD = 3258

export interface EasytimeController {
  visible: boolean
  values: EasytimeValues
  use24hr: boolean
  sliderValue: number
  disabled: {
    weather: boolean
    dynamic: boolean
    instantweather: boolean
    freeze: boolean
    instanttime: boolean
    slider: boolean
  }
  show: {
    realtime: boolean
    realweather: boolean
    newWeather: boolean
  }
  setUse24hr: (v: boolean) => void
  setWeather: (w: WeatherType) => void
  setTimeFromSlider: (value: number) => void
  toggleFreeze: () => void
  toggleBlackout: () => void
  toggleDynamic: () => void
  toggleTsunami: () => void
  toggleInstantTime: () => void
  toggleInstantWeather: () => void
  toggleRealtime: () => void
  toggleRealweather: () => void
  close: () => void
  applyChange: () => void
  applySave: () => void
}

export function useEasytime(): EasytimeController {
  const [visible, setVisible] = useState(false)
  const [values, setValues] = useState<EasytimeValues>(DEFAULT_VALUES)
  const [use24hr, setUse24hr] = useState(true)
  const weatherOnOpen = useRef<WeatherType>('CLEAR')

  // Lua → NUI: abre a tela com os valores atuais.
  useNuiEvent<{ values: EasytimeValues }>('open', ({ values: incoming }) => {
    const next: EasytimeValues = {
      ...incoming,
      realweather: incoming.weathermethod === 'real',
      realtime: incoming.timemethod === 'real',
    }
    weatherOnOpen.current = incoming.weather
    setValues(next)
    setVisible(true)
  })

  useNuiEvent('close', () => setVisible(false))

  const patch = useCallback((p: Partial<EasytimeValues>) => {
    setValues((prev) => ({ ...prev, ...p }))
  }, [])

  const setWeather = useCallback((weather: WeatherType) => patch({ weather }), [patch])

  const setTimeFromSlider = useCallback(
    (value: number) => {
      const { hours, minutes } = numToTime(value)
      const c = convertTime(hours, minutes)
      patch({ hours: c.hours, mins: c.minutes })
    },
    [patch],
  )

  const toggleFreeze = useCallback(() => setValues((p) => ({ ...p, freeze: !p.freeze })), [])
  const toggleBlackout = useCallback(() => setValues((p) => ({ ...p, blackout: !p.blackout })), [])
  const toggleDynamic = useCallback(() => setValues((p) => ({ ...p, dynamic: !p.dynamic })), [])
  const toggleTsunami = useCallback(() => setValues((p) => ({ ...p, tsunami: !p.tsunami })), [])

  // Os toggles "instant" avisam o servidor na hora (como no script.js original).
  const toggleInstantTime = useCallback(() => {
    setValues((p) => {
      const instanttime = !p.instanttime
      fetchNui('instanttime', { instanttime })
      return { ...p, instanttime }
    })
  }, [])

  const toggleInstantWeather = useCallback(() => {
    setValues((p) => {
      const instantweather = !p.instantweather
      fetchNui('instantweather', { instantweather })
      return { ...p, instantweather }
    })
  }, [])

  const toggleRealtime = useCallback(() => {
    setValues((p) => {
      const realtime = !p.realtime
      const timemethod: Method = realtime ? 'real' : 'game'
      return { ...p, realtime, timemethod }
    })
  }, [])

  const toggleRealweather = useCallback(() => {
    setValues((p) => {
      const realweather = !p.realweather
      const weathermethod: Method = realweather ? 'real' : 'game'
      // Ao ligar realweather, reverte a seleção manual para o clima de abertura.
      const weather = realweather ? weatherOnOpen.current : p.weather
      return { ...p, realweather, weathermethod, weather }
    })
  }, [])

  const buildPayload = useCallback(
    (): EasytimeValues => ({
      ...values,
      weathermethod: values.realweather ? 'real' : 'game',
      timemethod: values.realtime ? 'real' : 'game',
    }),
    [values],
  )

  const close = useCallback(() => {
    setVisible(false)
    fetchNui('close')
  }, [])

  // "Aplicar": envia mudanças mas mantém a tela aberta.
  const applyChange = useCallback(() => {
    fetchNui('change', { values: buildPayload(), savesettings: false })
  }, [buildPayload])

  // "Salvar": envia + persiste; o client.lua libera o foco do NUI.
  const applySave = useCallback(() => {
    fetchNui('change', { values: buildPayload(), savesettings: true })
    setVisible(false)
  }, [buildPayload])

  const sliderValue = useMemo(() => timeToSlider(values.hours, values.mins), [values.hours, values.mins])

  const disabled = useMemo(
    () => ({
      weather: values.realweather,
      dynamic: values.realweather,
      instantweather: values.realweather,
      freeze: values.realtime,
      instanttime: values.realtime,
      slider: values.realtime,
    }),
    [values.realweather, values.realtime],
  )

  const show = useMemo(
    () => ({
      realtime: values.original_timemethod !== 'game',
      realweather: values.original_weathermethod !== 'game',
      newWeather: Number(values.game_build) >= NEW_WEATHER_MIN_BUILD,
    }),
    [values.original_timemethod, values.original_weathermethod, values.game_build],
  )

  return {
    visible,
    values,
    use24hr,
    sliderValue,
    disabled,
    show,
    setUse24hr,
    setWeather,
    setTimeFromSlider,
    toggleFreeze,
    toggleBlackout,
    toggleDynamic,
    toggleTsunami,
    toggleInstantTime,
    toggleInstantWeather,
    toggleRealtime,
    toggleRealweather,
    close,
    applyChange,
    applySave,
  }
}
