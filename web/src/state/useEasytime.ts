import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { fetchNui } from '@/nui/fetchNui'
import { useNuiEvent } from '@/nui/useNuiEvent'
import { convertTime, numToTime, timeToSlider } from '@/lib/time'
import { applyAccentColor, applyBackgroundColor } from '@/lib/color'
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

export interface UseEasytimeOptions {
  /** Modo embedded (hospedado no mri_Qadmin). Busca o estado via getState e
   * não esconde a tela ao salvar (o host controla a visibilidade). */
  embedded?: boolean
}

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

export function useEasytime(opts: UseEasytimeOptions = {}): EasytimeController {
  const { embedded = false } = opts
  const [visible, setVisible] = useState(embedded)
  const [values, setValues] = useState<EasytimeValues>(DEFAULT_VALUES)
  const [use24hr, setUse24hr] = useState(true)
  const weatherOnOpen = useRef<WeatherType>('CLEAR')

  const hydrate = useCallback((incoming: EasytimeValues) => {
    const next: EasytimeValues = {
      ...incoming,
      realweather: incoming.weathermethod === 'real',
      realtime: incoming.timemethod === 'real',
    }
    weatherOnOpen.current = incoming.weather
    setValues(next)
    return next
  }, [])

  // Standalone: Lua → NUI abre a tela com os valores atuais (+ cor).
  useNuiEvent<{ values: EasytimeValues }>('open', ({ values: incoming }) => {
    hydrate(incoming)
    applyAccentColor(incoming.accentColor)
    applyBackgroundColor(incoming.backgroundColor)
    setVisible(true)
  })

  useNuiEvent('close', () => setVisible(false))

  // Atualização de cor em runtime (convar mudou) — standalone.
  useNuiEvent<{ accentColor: string }>('updateAccentColor', ({ accentColor }) => applyAccentColor(accentColor))
  useNuiEvent<{ backgroundColor: string }>('updateBackgroundColor', ({ backgroundColor }) =>
    applyBackgroundColor(backgroundColor),
  )

  // Embedded: busca o estado on-demand (não há push de 'open' pelo /clima).
  useEffect(() => {
    if (!embedded) return
    let cancelled = false
    fetchNui<EasytimeValues>('getState').then((data) => {
      if (cancelled || !data) return
      hydrate(data)
      setVisible(true)
    })
    return () => {
      cancelled = true
    }
  }, [embedded, hydrate])

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

  const applyChange = useCallback(() => {
    fetchNui('change', { values: buildPayload(), savesettings: false })
  }, [buildPayload])

  const applySave = useCallback(() => {
    fetchNui('change', { values: buildPayload(), savesettings: true })
    if (!embedded) setVisible(false)
  }, [buildPayload, embedded])

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
