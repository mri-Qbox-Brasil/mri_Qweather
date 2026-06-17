import { useEffect, useState } from 'react'
import { ChevronDown, RefreshCw, Trash2 } from 'lucide-react'
import { WEATHER_OPTIONS } from './weather'
import type { ForecastEvent } from '@/state/useForecast'
import type { WeatherType } from '@/nui/types'

// Climas válidos pra fila (mesmo conjunto que o server aceita — exclui os
// halloween/neutro que não estão nos WeatherGroups).
const FORECAST_WEATHERS: WeatherType[] = [
  'CLEAR', 'EXTRASUNNY', 'CLOUDS', 'OVERCAST', 'RAIN', 'CLEARING',
  'THUNDER', 'SMOG', 'FOGGY', 'SNOW', 'SNOWLIGHT', 'BLIZZARD', 'XMAS',
]

const META = Object.fromEntries(WEATHER_OPTIONS.map((o) => [o.id, o])) as Record<
  WeatherType,
  (typeof WEATHER_OPTIONS)[number]
>
const labelOf = (w: WeatherType) => META[w]?.label ?? w

interface Props {
  events: ForecastEvent[]
  enabled: boolean
  loading: boolean
  disabled?: boolean
  onRefresh: () => void
  onSetWeather: (index: number, weather: WeatherType) => void
  onSetTime: (index: number, time: number) => void
  onRemove: (index: number) => void
}

export function ForecastSection({
  events,
  enabled,
  loading,
  disabled,
  onRefresh,
  onSetWeather,
  onSetTime,
  onRemove,
}: Props) {
  if (events.length === 0) return null

  // Minuto acumulado em que cada evento começa (a partir de "agora").
  let acc = 0
  const startsAt = events.map((e) => {
    const at = acc
    acc += e.time
    return at
  })

  return (
    <div className="flex h-full min-h-0 flex-col gap-2.5">
      <div className="flex items-center justify-between px-0.5">
        <div className="flex items-baseline gap-2">
          <h3 className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground/70">
            Previsão
          </h3>
          <span className="rounded-full bg-muted px-1.5 py-px text-[9px] tabular-nums text-muted-foreground">
            {events.length}
          </span>
        </div>
        <button
          type="button"
          onClick={onRefresh}
          title="Atualizar"
          className="rounded-md p-1 text-muted-foreground/60 transition-colors hover:bg-muted/60 hover:text-foreground"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${loading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      {!enabled && (
        <p className="rounded-xl bg-muted/30 px-3 py-2 text-[11px] leading-snug text-muted-foreground/80">
          Ative o <span className="font-medium text-foreground">Clima dinâmico</span> para a previsão avançar
          automaticamente.
        </p>
      )}

      <div className="min-h-0 flex-1 overflow-auto rounded-2xl bg-muted/40">
        <div className="divide-y divide-border/30">
          {events.map((ev, i) => (
            <ForecastRow
              key={i}
              event={ev}
              index={i + 1}
              isCurrent={i === 0}
              startsAt={startsAt[i]}
              disabled={disabled}
              onSetWeather={onSetWeather}
              onSetTime={onSetTime}
              onRemove={onRemove}
            />
          ))}
        </div>
      </div>
    </div>
  )
}

interface RowProps {
  event: ForecastEvent
  index: number
  isCurrent: boolean
  startsAt: number
  disabled?: boolean
  onSetWeather: (index: number, weather: WeatherType) => void
  onSetTime: (index: number, time: number) => void
  onRemove: (index: number) => void
}

function ForecastRow({ event, index, isCurrent, startsAt, disabled, onSetWeather, onSetTime, onRemove }: RowProps) {
  const Icon = META[event.weather]?.icon
  return (
    <div className={`group flex items-center gap-3 px-3 py-2.5 ${isCurrent ? 'bg-primary/[0.06]' : ''}`}>
      <div
        className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ${
          isCurrent ? 'bg-primary/15 text-primary' : 'bg-muted text-muted-foreground'
        }`}
      >
        {Icon && <Icon className="h-[18px] w-[18px]" />}
      </div>

      {/* Seletor de clima (linha limpa com chevron; o <select> nativo cobre a área) */}
      <div className="relative min-w-0 flex-1">
        <div className="flex items-center gap-1">
          <span className="truncate text-[14px] font-medium text-foreground">{labelOf(event.weather)}</span>
          {!disabled && <ChevronDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground/50" />}
        </div>
        <div className="mt-0.5 text-[11px] tabular-nums text-muted-foreground/70">
          {isCurrent ? 'agora' : `em ${formatOffset(startsAt)}`}
        </div>
        <select
          value={event.weather}
          disabled={disabled}
          onChange={(e) => onSetWeather(index, e.target.value as WeatherType)}
          aria-label="Clima do evento"
          className="absolute inset-0 cursor-pointer opacity-0 disabled:cursor-not-allowed"
        >
          {FORECAST_WEATHERS.map((w) => (
            <option key={w} value={w} className="bg-background text-foreground">
              {labelOf(w)}
            </option>
          ))}
        </select>
      </div>

      <DurationInput value={event.time} disabled={disabled} onCommit={(t) => onSetTime(index, t)} />

      <button
        type="button"
        disabled={disabled}
        onClick={() => onRemove(index)}
        title="Remover evento"
        className="shrink-0 rounded-md p-1 text-muted-foreground/40 opacity-0 transition-all hover:bg-destructive/10 hover:text-destructive group-hover:opacity-100 disabled:cursor-not-allowed disabled:opacity-0"
      >
        <Trash2 className="h-4 w-4" />
      </button>
    </div>
  )
}

// Pílula de duração (minutos) que só comita no blur / Enter pra não spammar o server.
function DurationInput({
  value,
  disabled,
  onCommit,
}: {
  value: number
  disabled?: boolean
  onCommit: (time: number) => void
}) {
  const [draft, setDraft] = useState(String(value))
  useEffect(() => setDraft(String(value)), [value])

  const commit = () => {
    const n = Math.max(1, Math.floor(Number(draft) || 0))
    if (n !== value) onCommit(n)
    else setDraft(String(value))
  }

  return (
    <div
      className={`flex shrink-0 items-center gap-1 rounded-lg bg-background/60 px-2 py-1 ${
        disabled ? 'opacity-50' : 'focus-within:ring-1 focus-within:ring-primary/40'
      }`}
    >
      <input
        type="number"
        min={1}
        value={draft}
        disabled={disabled}
        onChange={(e) => setDraft(e.target.value)}
        onBlur={commit}
        onKeyDown={(e) => {
          if (e.key === 'Enter') (e.target as HTMLInputElement).blur()
        }}
        aria-label="Duração em minutos"
        className="w-8 bg-transparent text-right text-[13px] font-medium tabular-nums text-foreground outline-none [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none"
      />
      <span className="text-[10px] text-muted-foreground/70">min</span>
    </div>
  )
}

// 90 → "1h30", 45 → "45min"
function formatOffset(minutes: number): string {
  if (minutes < 60) return `${minutes}min`
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return m === 0 ? `${h}h` : `${h}h${String(m).padStart(2, '0')}`
}
