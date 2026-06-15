import type { EasytimeValues } from './types'

// Harness de desenvolvimento: como no navegador o client.lua não existe,
// simulamos a mensagem `open` que ele mandaria. Também expõe helpers no
// console: `easytimeMock.open()`, `.close()`, `.playsound()`.

const SAMPLE: EasytimeValues = {
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
  game_build: 3258,
  weathermethod: 'game',
  timemethod: 'game',
  original_weathermethod: 'game',
  original_timemethod: 'game',
  real_info: {
    weather: 'Clouds',
    weather_description: 'broken clouds',
    country: 'BR',
    city: 'São Paulo',
  },
}

export function startMockNui(): void {
  const open = (override: Partial<EasytimeValues> = {}) =>
    window.postMessage({ action: 'open', values: { ...SAMPLE, ...override } }, '*')

  ;(window as unknown as { easytimeMock: unknown }).easytimeMock = {
    open,
    close: () => window.postMessage({ action: 'close' }, '*'),
    playsound: () => window.postMessage({ action: 'playsound' }, '*'),
  }

  // Abre automaticamente ao carregar para já vermos a tela.
  setTimeout(() => open(), 300)
}
