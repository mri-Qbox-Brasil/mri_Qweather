import { memo, useEffect, useRef, useState, type ReactNode } from 'react'
import { ChevronDown, Minus, Plus, RefreshCw, Trash2 } from 'lucide-react'
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
  const [openIndex, setOpenIndex] = useState<number | null>(null)

  if (events.length === 0) return null

  // Minuto acumulado em que cada evento começa (a partir de "agora").
  let acc = 0
  const startsAt = events.map((e) => {
    const at = acc
    acc += e.time
    return at
  })

  const handleRemove = (i: number) => {
    setOpenIndex(null)
    onRemove(i)
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between px-0.5">
        <p className="text-[11px] text-muted-foreground/80">
          {enabled ? 'Avançando automaticamente' : 'Pausada'}
        </p>
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
          Ative o <span className="font-medium text-foreground">Clima dinâmico</span> (aba Clima &amp; Hora) para a
          previsão avançar sozinha.
        </p>
      )}

      <div className="space-y-1.5">
        {events.map((ev, i) => {
          const index = i + 1
          return (
            <ForecastRow
              key={index}
              event={ev}
              index={index}
              isCurrent={i === 0}
              startsAt={startsAt[i]}
              expanded={openIndex === index}
              disabled={disabled}
              onToggle={() => setOpenIndex((cur) => (cur === index ? null : index))}
              onSetWeather={onSetWeather}
              onSetTime={onSetTime}
              onRemove={handleRemove}
            />
          )
        })}
      </div>
    </div>
  )
}

interface RowProps {
  event: ForecastEvent
  index: number
  isCurrent: boolean
  startsAt: number
  expanded: boolean
  disabled?: boolean
  onToggle: () => void
  onSetWeather: (index: number, weather: WeatherType) => void
  onSetTime: (index: number, time: number) => void
  onRemove: (index: number) => void
}

const ForecastRow = memo(function ForecastRow({
  event,
  index,
  isCurrent,
  startsAt,
  expanded,
  disabled,
  onToggle,
  onSetWeather,
  onSetTime,
  onRemove,
}: RowProps) {
  const Icon = META[event.weather]?.icon

  // Duração com commit debounced — o stepper responde na hora, mas só bate no
  // server depois de 450ms parado (evita flood / reflow da lista sob o dedo).
  const [timeDraft, setTimeDraft] = useState(event.time)
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => setTimeDraft(event.time), [event.time])
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const commitTime = (next: number) => {
    const n = Math.min(1440, Math.max(1, Math.floor(next || 1)))
    setTimeDraft(n)
    window.clearTimeout(timer.current)
    timer.current = window.setTimeout(() => onSetTime(index, n), 450)
  }

  return (
    <div
      className={`overflow-hidden rounded-xl transition-colors ${
        isCurrent ? 'bg-primary/[0.07] ring-1 ring-primary/25' : 'bg-muted/30'
      }`}
    >
      <button
        type="button"
        onClick={disabled ? undefined : onToggle}
        disabled={disabled}
        className="flex w-full items-center gap-3 px-2.5 py-2 text-left transition-colors hover:bg-foreground/[0.03] disabled:cursor-default disabled:hover:bg-transparent"
      >
        <div
          className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ${
            isCurrent ? 'bg-primary/15 text-primary' : 'bg-background/60 text-muted-foreground'
          }`}
        >
          {Icon && <Icon className="h-[18px] w-[18px]" />}
        </div>

        <div className="min-w-0 flex-1">
          <div className="truncate text-[14px] font-medium text-foreground">{labelOf(event.weather)}</div>
          <div className="text-[11px] tabular-nums text-muted-foreground/70">
            {isCurrent ? (
              <span className="font-medium text-primary">agora</span>
            ) : (
              `começa em ${formatOffset(startsAt)}`
            )}
          </div>
        </div>

        <div className="shrink-0 text-[13px] font-medium tabular-nums text-muted-foreground">{timeDraft} min</div>

        {!disabled && (
          <ChevronDown
            className={`h-4 w-4 shrink-0 text-muted-foreground/50 transition-transform ${expanded ? 'rotate-180' : ''}`}
          />
        )}
      </button>

      {expanded && !disabled && (
        <div className="space-y-3 border-t border-border/40 px-2.5 pb-3 pt-3">
          <div>
            <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground/60">
              Clima
            </p>
            <div className="grid grid-cols-4 gap-1">
              {FORECAST_WEATHERS.map((w) => {
                const WIcon = META[w]?.icon
                const active = w === event.weather
                return (
                  <button
                    key={w}
                    type="button"
                    onClick={() => onSetWeather(index, w)}
                    title={labelOf(w)}
                    className={`flex flex-col items-center gap-1 rounded-lg px-1 py-1.5 transition-all ${
                      active
                        ? 'bg-primary/15 text-primary ring-1 ring-primary/40'
                        : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                    }`}
                  >
                    {WIcon && <WIcon className="h-[15px] w-[15px]" />}
                    <span className="text-[9px] font-medium leading-tight">{labelOf(w)}</span>
                  </button>
                )
              })}
            </div>
          </div>

          <div className="flex items-center justify-between">
            <p className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground/60">Duração</p>
            <div className="flex items-center gap-1.5">
              <StepButton onClick={() => commitTime(timeDraft - 5)} disabled={timeDraft <= 1} label="Diminuir">
                <Minus className="h-3.5 w-3.5" />
              </StepButton>
              <input
                type="text"
                inputMode="numeric"
                value={timeDraft}
                onChange={(e) => commitTime(Number(e.target.value.replace(/\D/g, '')))}
                aria-label="Duração em minutos"
                className="h-7 w-12 rounded-md border border-border bg-background/60 text-center text-[13px] font-medium tabular-nums text-foreground outline-none focus:border-ring"
              />
              <span className="text-[11px] text-muted-foreground/70">min</span>
              <StepButton onClick={() => commitTime(timeDraft + 5)} disabled={timeDraft >= 1440} label="Aumentar">
                <Plus className="h-3.5 w-3.5" />
              </StepButton>
            </div>
          </div>

          <button
            type="button"
            onClick={() => onRemove(index)}
            className="flex w-full items-center justify-center gap-2 rounded-lg bg-destructive/10 py-2 text-[13px] font-medium text-destructive transition-colors hover:bg-destructive/20"
          >
            <Trash2 className="h-3.5 w-3.5" />
            Remover evento
          </button>
        </div>
      )}
    </div>
  )
}, areRowsEqual)

// Só re-renderiza a linha quando os dados que ela mostra mudam (ignora a
// identidade dos callbacks). Mantém expandir/colapsar barato com 46 linhas.
function areRowsEqual(prev: RowProps, next: RowProps): boolean {
  return (
    prev.expanded === next.expanded &&
    prev.isCurrent === next.isCurrent &&
    prev.disabled === next.disabled &&
    prev.index === next.index &&
    prev.startsAt === next.startsAt &&
    prev.event.weather === next.event.weather &&
    prev.event.time === next.event.time
  )
}

function StepButton({
  children,
  onClick,
  disabled,
  label,
}: {
  children: ReactNode
  onClick: () => void
  disabled?: boolean
  label: string
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-label={label}
      className="flex h-7 w-7 items-center justify-center rounded-md bg-muted text-muted-foreground transition-colors hover:bg-muted/70 hover:text-foreground disabled:cursor-not-allowed disabled:opacity-40"
    >
      {children}
    </button>
  )
}

// 90 → "1h30", 45 → "45min"
function formatOffset(minutes: number): string {
  if (minutes < 60) return `${minutes}min`
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return m === 0 ? `${h}h` : `${h}h${String(m).padStart(2, '0')}`
}
