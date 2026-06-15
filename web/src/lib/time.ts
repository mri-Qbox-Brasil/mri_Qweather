// Utilitários de tempo portados de html/js/script.js (numToTime / convertTime /
// formatação 24h-12h).

/** Converte o valor contínuo do slider (ex: 8.5) em { hours, minutes }. */
export function numToTime(value: number): { hours: number; minutes: number } {
  const hours = Math.floor(value)
  const decimal = value - hours
  const minutes = Math.floor(decimal * 60)
  return { hours, minutes }
}

/** Normaliza horas >= 24 (o slider vai até 31 = 7h do dia seguinte). */
export function convertTime(hours: number, minutes: number): { hours: number; minutes: number } {
  if (hours >= 24) return { hours: Math.abs(hours - 24), minutes }
  return { hours, minutes }
}

/**
 * Valor do slider a partir de hours/mins. Horas de 1–7 são mapeadas para
 * 25–31 (madrugada do "dia seguinte"), espelhando o script.js original.
 */
export function timeToSlider(hours: number, mins: number): number {
  return hours >= 1 && hours <= 7 ? hours + 24 + mins / 60 : hours + mins / 60
}

/** Formata para exibição em 24h ou 12h (AM/PM). */
export function formatTime(hours: number, minutes: number, use24hr: boolean): string {
  const t = convertTime(hours, minutes)
  const iso = `1970-02-02T${pad(t.hours)}:${pad(t.minutes)}:00Z`
  return new Date(iso).toLocaleTimeString(use24hr ? 'de-DE' : 'en-US', {
    hour12: !use24hr,
    hour: 'numeric',
    minute: 'numeric',
    timeZone: 'UTC',
  })
}

function pad(n: number): string {
  return n < 10 ? `0${n}` : `${n}`
}
