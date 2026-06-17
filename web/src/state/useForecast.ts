import { useCallback, useEffect, useState } from 'react'
import { fetchNui } from '@/nui/fetchNui'
import type { WeatherType } from '@/nui/types'

// Espelha um evento da fila de previsão do server (server/forecast.lua).
export interface ForecastEvent {
  weather: WeatherType
  time: number
  windSpeed?: number
  windDirection?: number
  hasSnow?: boolean
}

export interface ForecastState {
  enabled: boolean
  events: ForecastEvent[]
}

const EMPTY: ForecastState = { enabled: false, events: [] }

/**
 * Gerencia a fila de previsão: busca on-demand (poll enquanto aberto) e expõe as
 * mutações (trocar clima, mudar duração, remover) que batem nos callbacks do
 * server via NUI. Os índices são 1-based (Lua).
 */
export function useForecast(open: boolean) {
  const [state, setState] = useState<ForecastState>(EMPTY)
  const [loading, setLoading] = useState(false)

  const refresh = useCallback(async () => {
    setLoading(true)
    const data = await fetchNui<ForecastState | false>('getForecast')
    setState(data && typeof data === 'object' && Array.isArray(data.events) ? data : EMPTY)
    setLoading(false)
  }, [])

  // Busca inicial uma vez (pra saber se há fila e mostrar a aba).
  useEffect(() => {
    void refresh()
  }, [refresh])

  // Poll só enquanto a aba Previsão está ativa (evita re-render à toa).
  useEffect(() => {
    if (!open) return
    const id = window.setInterval(() => void refresh(), 20000)
    return () => window.clearInterval(id)
  }, [open, refresh])

  const setWeather = useCallback(
    async (index: number, weather: WeatherType) => {
      const res = await fetchNui('setForecastWeather', { index, weather })
      if (res) await refresh()
    },
    [refresh],
  )

  const setTime = useCallback(
    async (index: number, time: number) => {
      const res = await fetchNui('setForecastTime', { index, time })
      if (res) await refresh()
    },
    [refresh],
  )

  const remove = useCallback(
    async (index: number) => {
      const res = await fetchNui('removeForecastEvent', { index })
      if (res) await refresh()
    },
    [refresh],
  )

  return { state, loading, refresh, setWeather, setTime, remove }
}
