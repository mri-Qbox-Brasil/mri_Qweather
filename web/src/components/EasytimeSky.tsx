import { useMemo } from 'react'

// Header animado (sol/lua + nuvens/estrelas) calculado a partir do horário.

interface SkyProps {
  hours: number
  mins: number
}

interface SkyState {
  isDay: boolean
  body: { leftPct: number; bottomPct: number }
}

function clamp(n: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, n))
}

function computeSky(hours: number, mins: number): SkyState {
  let time = hours + mins / 60
  if (time === 0) time = 24

  // Manhã (8–12): sol subindo pela esquerda.
  if (time >= 8 && time <= 12) {
    const t = time - 8
    return { isDay: true, body: { leftPct: clamp((t / 8) * 100, 4, 86), bottomPct: clamp((t / 4) * 70, 8, 70) } }
  }
  // Dia (12–21): sol descendo pela direita.
  if (time > 12 && time < 21) {
    const t = time - 12
    return { isDay: true, body: { leftPct: clamp((t / 16) * 100 + 50, 4, 86), bottomPct: clamp(70 - (t / 8) * 70, 8, 70) } }
  }
  // Anoitecer (21–24): lua subindo pela esquerda.
  if (time >= 21 && time <= 24) {
    const t = time - 20
    return { isDay: false, body: { leftPct: clamp((t / 8) * 100, 4, 86), bottomPct: clamp((t / 4) * 70, 8, 70) } }
  }
  // Madrugada (0–8): lua descendo pela direita.
  const t = time
  return { isDay: false, body: { leftPct: clamp((t / 14) * 100 + 50, 4, 86), bottomPct: clamp(70 - (t / 7) * 70, 8, 70) } }
}

function useDecorations(isDay: boolean) {
  return useMemo(() => {
    const count = isDay ? 10 : 36
    return Array.from({ length: count }, () => ({
      size: isDay ? Math.floor(Math.random() * 46) + 18 : Math.random() * 2 + 1,
      top: Math.floor(Math.random() * 86),
      left: Math.floor(Math.random() * 96),
      opacity: isDay ? Math.random() * 0.3 + 0.12 : Math.random() * 0.8 + 0.2,
    }))
  }, [isDay])
}

export function EasytimeSky({ hours, mins }: SkyProps) {
  const { isDay, body } = computeSky(hours, mins)
  const deco = useDecorations(isDay)

  return (
    <div
      className="relative h-24 w-full overflow-hidden transition-colors duration-700"
      style={{
        background: isDay
          ? 'linear-gradient(160deg, #2f74d6 0%, #69adea 45%, #bcdcf5 100%)'
          : 'linear-gradient(160deg, #070b20 0%, #141d40 60%, #27315a 100%)',
      }}
    >
      {/* Nuvens (dia) ou estrelas (noite) */}
      {deco.map((d, i) => (
        <span
          key={i}
          className={isDay ? 'absolute rounded-full bg-white blur-[6px]' : 'absolute rounded-full bg-white'}
          style={{
            width: d.size,
            height: isDay ? d.size * 0.42 : d.size,
            top: `${d.top}%`,
            left: `${d.left}%`,
            opacity: d.opacity,
            boxShadow: isDay ? undefined : '0 0 4px rgba(255,255,255,0.6)',
          }}
        />
      ))}

      {/* Sol ou Lua */}
      <div
        className="absolute h-8 w-8 rounded-full transition-all duration-500"
        style={{
          left: `${body.leftPct}%`,
          bottom: `${body.bottomPct}%`,
          background: isDay
            ? 'radial-gradient(circle, #fffef0 0%, #ffd84d 55%, #ffb52e 100%)'
            : 'radial-gradient(circle, #ffffff 0%, #dfe5f7 70%, #b4bce0 100%)',
          boxShadow: isDay ? '0 0 28px 10px rgba(255, 205, 70, 0.55)' : '0 0 18px 6px rgba(200, 212, 255, 0.4)',
        }}
      />

      {/* Fade inferior para fundir com o corpo do card */}
      <div className="pointer-events-none absolute inset-x-0 bottom-0 h-12 bg-gradient-to-b from-transparent to-black/40" />
    </div>
  )
}
