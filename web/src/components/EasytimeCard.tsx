import { useEffect, useRef, useState, type PointerEvent as ReactPointerEvent, type ReactNode } from 'react'
import { SlidersHorizontal, CalendarClock, Sun, Moon, Minus, Plus, type LucideIcon } from 'lucide-react'
import { MriButton, MriCard, MriCardContent, MriCardFooter, MriSwitch } from '@mriqbox/ui-kit'
import { useEasytime, type EasytimeController } from '@/state/useEasytime'
import { useNuiEvent } from '@/nui/useNuiEvent'
import { formatTime } from '@/lib/time'
import { WEATHER_OPTIONS, type WeatherOption } from './weather'
import { EasytimeSky } from './EasytimeSky'
import { ForecastSection } from './ForecastSection'
import { useForecast } from '@/state/useForecast'
import { useDraggable } from '@/lib/useDraggable'

const SLIDER_MIN = 8
const SLIDER_MAX = 31

// ─── Wrapper standalone (NUI própria, aberta via /clima) ───────────────────
export function EasytimeCard() {
  const c = useEasytime()
  const { visible, close } = c
  const audioRef = useRef<HTMLAudioElement>(null)
  const { pos, dragRef, onHandlePointerDown } = useDraggable()

  useNuiEvent('playsound', () => {
    const a = audioRef.current
    if (!a) return
    a.volume = 0.5
    a.currentTime = 0
    void a.play().catch(() => undefined)
  })

  const audio = (
    <audio ref={audioRef} src={`${import.meta.env.BASE_URL}sound/tsunami_siren.ogg`} preload="auto" />
  )

  if (!visible) return audio

  return (
    <>
      {audio}
      <div
        ref={dragRef}
        className={`fixed z-50 font-sans ${
          pos ? 'left-0 top-0 will-change-transform' : 'bottom-8 left-1/2 -translate-x-1/2 animate-slide-in-bottom'
        }`}
        style={pos ? { transform: `translate3d(${pos.x}px, ${pos.y}px, 0)` } : undefined}
      >
        <EasytimePanel c={c} onClose={close} onHandlePointerDown={onHandlePointerDown} />
      </div>
    </>
  )
}

// ─── Painel reutilizável (standalone + embedded no mri_Qadmin) ─────────────
interface PanelProps {
  c: EasytimeController
  onClose: () => void
  /** Quando embedded (Qadmin), sem drag, ocupa o iframe inteiro e não esconde. */
  embedded?: boolean
  onHandlePointerDown?: (e: ReactPointerEvent<HTMLElement>) => void
}

type Tab = 'controls' | 'forecast'

export function EasytimePanel({ c, onClose, embedded = false, onHandlePointerDown }: PanelProps) {
  const { values } = c
  const [tab, setTab] = useState<Tab>('controls')
  const fc = useForecast(tab === 'forecast')
  const hasForecast = fc.state.events.length > 0

  const weathers = WEATHER_OPTIONS.filter((w) => (w.isNew ? c.show.newWeather : true))
  const fill = ((c.sliderValue - SLIDER_MIN) / (SLIDER_MAX - SLIDER_MIN)) * 100

  // Escala do tempo: converte segundos/min-de-jogo ↔ minutos reais da fase,
  // usando a janela noturna (config). night fora de [start,end) = dia.
  const nightStart = values.night_start ?? 22
  const nightEnd = values.night_end ?? 6
  const nightGameMin = ((((nightEnd - nightStart) % 24) + 24) % 24) * 60
  const dayGameMin = 1440 - nightGameMin
  const dayRealMin = dayGameMin > 0 ? Math.max(1, Math.round(((values.dayscale ?? 5) * dayGameMin) / 60)) : 0
  const nightRealMin = nightGameMin > 0 ? Math.max(1, Math.round(((values.nightscale ?? 5) * nightGameMin) / 60)) : 0
  const setDayMin = (m: number) => {
    if (dayGameMin > 0) c.setDayScale((Math.min(600, Math.max(1, m)) * 60) / dayGameMin)
  }
  const setNightMin = (m: number) => {
    if (nightGameMin > 0) c.setNightScale((Math.min(600, Math.max(1, m)) * 60) / nightGameMin)
  }

  // ESC fecha — standalone chama close(), embedded pede requestClose ao host.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])

  const showForecast = hasForecast && tab === 'forecast'

  const controls = (
    <div className="flex flex-col gap-5">
      <div className="-mt-1 text-center text-6xl font-semibold leading-none tracking-tight tabular-nums text-foreground">
        {formatTime(values.hours, values.mins, c.use24hr)}
      </div>

      <input
        type="range"
        min={SLIDER_MIN}
        max={SLIDER_MAX}
        step={0.01}
        value={c.sliderValue}
        disabled={c.disabled.slider}
        onChange={(e) => c.setTimeFromSlider(parseFloat(e.target.value))}
        aria-label="Hora do dia"
        className="easytime-slider w-full"
        style={{
          backgroundImage: `linear-gradient(to right, hsl(var(--primary)) ${fill}%, hsl(var(--muted)) ${fill}%)`,
        }}
      />

      <section className="space-y-2.5">
        <SectionLabel>Clima</SectionLabel>
        <div className="grid grid-cols-4 gap-1.5">
          {weathers.map((w) => (
            <WeatherTile
              key={w.id}
              option={w}
              active={values.weather === w.id}
              disabled={c.disabled.weather}
              onClick={() => c.setWeather(w.id)}
            />
          ))}
        </div>
      </section>

      <section className="space-y-2.5">
        <SectionLabel>Ajustes</SectionLabel>
        <div className="grid grid-cols-2 gap-x-3 gap-y-0.5 rounded-2xl bg-muted/30 p-1.5">
          <ToggleRow label="24 horas" title="Apenas exibição" checked={c.use24hr} onChange={c.setUse24hr} />
          <ToggleRow label="Congelar tempo" checked={values.freeze} onChange={c.toggleFreeze} disabled={c.disabled.freeze} />
          <ToggleRow label="Blackout" checked={values.blackout} onChange={c.toggleBlackout} />
          <ToggleRow label="Clima dinâmico" checked={values.dynamic} onChange={c.toggleDynamic} disabled={c.disabled.dynamic} />
          <ToggleRow label="Tempo instantâneo" checked={values.instanttime} onChange={c.toggleInstantTime} disabled={c.disabled.instanttime} />
          <ToggleRow label="Clima instantâneo" checked={values.instantweather} onChange={c.toggleInstantWeather} disabled={c.disabled.instantweather} />
          <ToggleRow label="Tsunami" checked={values.tsunami} onChange={c.toggleTsunami} />
          {c.show.realtime && (
            <ToggleRow label="Usar tempo real" checked={values.realtime} onChange={c.toggleRealtime} />
          )}
          {c.show.realweather && (
            <ToggleRow label="Usar clima real" checked={values.realweather} onChange={c.toggleRealweather} />
          )}
        </div>
      </section>

      <section className="space-y-2.5">
        <SectionLabel>Velocidade do tempo</SectionLabel>
        <div className="space-y-0.5 rounded-2xl bg-muted/30 p-1.5">
          <ScaleRow icon={Sun} label="Dia" minutes={dayRealMin} disabled={values.realtime} onChange={setDayMin} />
          {nightGameMin > 0 && (
            <ScaleRow
              icon={Moon}
              label="Noite"
              minutes={nightRealMin}
              disabled={values.realtime}
              onChange={setNightMin}
            />
          )}
        </div>
      </section>

      {(c.show.realtime || c.show.realweather) && values.real_info?.city && (
        <div className="rounded-2xl bg-muted/30 px-3 py-2 text-xs text-muted-foreground">
          <span className="font-semibold text-foreground">
            {values.real_info.city}, {values.real_info.country}
          </span>
          {values.real_info.weather && (
            <div className="mt-0.5">
              {values.real_info.weather} — {values.real_info.weather_description}
            </div>
          )}
        </div>
      )}
    </div>
  )

  return (
    <MriCard
      className={
        embedded
          ? 'flex h-full flex-col rounded-none border-0 bg-transparent font-sans shadow-none'
          : `flex max-h-[88vh] w-[420px] transform-gpu flex-col overflow-hidden rounded-3xl border-0 font-sans shadow-2xl shadow-black/50 [backface-visibility:hidden] ${
              hasForecast ? 'h-[640px]' : ''
            }`
      }
    >
      {/* Header (céu) — alça de drag só no standalone */}
      <div
        onPointerDown={embedded ? undefined : onHandlePointerDown}
        className={`relative shrink-0 select-none ${embedded ? '' : 'cursor-grab active:cursor-grabbing'}`}
        title={embedded ? undefined : 'Arraste para mover'}
      >
        <EasytimeSky hours={values.hours} mins={values.mins} />
        {!embedded && (
          <div className="absolute left-1/2 top-2.5 h-1 w-9 -translate-x-1/2 rounded-full bg-white/50" />
        )}
      </div>

      {hasForecast && (
        <div className="shrink-0 px-4 pt-3">
          <SegTabs
            value={tab}
            onChange={(id) => setTab(id as Tab)}
            items={[
              { id: 'controls', label: 'Clima & Hora', icon: SlidersHorizontal },
              {
                id: 'forecast',
                icon: CalendarClock,
                label: (
                  <span className="inline-flex items-center gap-1.5">
                    Previsão
                    <span className="rounded-full bg-foreground/10 px-1.5 text-[10px] tabular-nums">
                      {fc.state.events.length}
                    </span>
                  </span>
                ),
              },
            ]}
          />
        </div>
      )}

      <MriCardContent className="min-h-0 flex-1 overflow-y-auto p-5">
        {showForecast ? (
          <ForecastSection
            events={fc.state.events}
            enabled={fc.state.enabled}
            loading={fc.loading}
            disabled={values.realweather}
            onRefresh={fc.refresh}
            onSetWeather={fc.setWeather}
            onSetTime={fc.setTime}
            onRemove={fc.remove}
          />
        ) : (
          controls
        )}
      </MriCardContent>

      <MriCardFooter className="shrink-0 gap-2 border-t border-border/40 px-5 pb-5 pt-4">
        <MriButton variant="ghost" size="sm" className="mr-auto" onClick={onClose}>
          Fechar
        </MriButton>
        <MriButton variant="secondary" size="sm" onClick={c.applyChange}>
          Aplicar
        </MriButton>
        <MriButton size="sm" onClick={c.applySave}>
          Salvar
        </MriButton>
      </MriCardFooter>
    </MriCard>
  )
}

interface SegTabsItem {
  id: string
  label: ReactNode
  icon?: LucideIcon
}

// Segmented control caseiro — sem backdrop-filter (o MriSegmentedTabs usava
// backdrop-blur, que é caro no CEF e dá artefato de fundo preto).
function SegTabs({
  value,
  onChange,
  items,
}: {
  value: string
  onChange: (id: string) => void
  items: SegTabsItem[]
}) {
  return (
    <div className="flex gap-1 rounded-xl bg-muted/40 p-1">
      {items.map((it) => {
        const active = it.id === value
        const Icon = it.icon
        return (
          <button
            key={it.id}
            type="button"
            onClick={() => onChange(it.id)}
            className={`flex flex-1 items-center justify-center gap-1.5 rounded-lg px-3 py-1.5 text-[13px] font-medium transition-colors ${
              active ? 'bg-background text-foreground shadow-sm' : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            {Icon && <Icon className="h-3.5 w-3.5" />}
            {it.label}
          </button>
        )
      })}
    </div>
  )
}

interface ScaleRowProps {
  icon: LucideIcon
  label: string
  minutes: number
  disabled?: boolean
  onChange: (minutes: number) => void
}

// Linha de escala (Dia/Noite) em minutos reais. Input editável + stepper ±5.
function ScaleRow({ icon: Icon, label, minutes, disabled, onChange }: ScaleRowProps) {
  const [draft, setDraft] = useState(String(minutes))
  useEffect(() => setDraft(String(minutes)), [minutes])

  const commit = () => {
    const n = Math.min(600, Math.max(1, Math.floor(Number(draft) || 1)))
    if (n !== minutes) onChange(n)
    else setDraft(String(minutes))
  }

  return (
    <div className={`flex items-center justify-between gap-2 rounded-lg px-2 py-1 ${disabled ? 'opacity-50' : ''}`}>
      <div className="flex items-center gap-2 text-[13px] text-muted-foreground">
        <Icon className="h-4 w-4" />
        {label}
      </div>
      <div className="flex items-center gap-1.5">
        <ScaleStep label="Diminuir" disabled={disabled || minutes <= 1} onClick={() => onChange(minutes - 5)}>
          <Minus className="h-3.5 w-3.5" />
        </ScaleStep>
        <div
          className={`flex items-center gap-1 rounded-md border border-border bg-background/60 px-2 py-0.5 ${
            disabled ? '' : 'focus-within:border-ring'
          }`}
        >
          <input
            type="text"
            inputMode="numeric"
            value={draft}
            disabled={disabled}
            onChange={(e) => setDraft(e.target.value.replace(/\D/g, ''))}
            onBlur={commit}
            onKeyDown={(e) => {
              if (e.key === 'Enter') (e.target as HTMLInputElement).blur()
            }}
            aria-label={`Duração — ${label}`}
            className="w-8 bg-transparent text-right text-[13px] font-medium tabular-nums text-foreground outline-none disabled:cursor-not-allowed"
          />
          <span className="text-[10px] text-muted-foreground/70">min</span>
        </div>
        <ScaleStep label="Aumentar" disabled={disabled} onClick={() => onChange(minutes + 5)}>
          <Plus className="h-3.5 w-3.5" />
        </ScaleStep>
      </div>
    </div>
  )
}

function ScaleStep({
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

function SectionLabel({ children }: { children: ReactNode }) {
  return (
    <p className="px-0.5 text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground/70">
      {children}
    </p>
  )
}

interface WeatherTileProps {
  option: WeatherOption
  active: boolean
  disabled?: boolean
  onClick: () => void
}

function WeatherTile({ option, active, disabled, onClick }: WeatherTileProps) {
  const Icon = option.icon
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      title={option.label}
      aria-pressed={active}
      className={`flex flex-col items-center justify-start gap-1 rounded-xl px-1 py-2 text-center transition-all ${
        disabled
          ? 'cursor-not-allowed opacity-40'
          : active
            ? 'bg-primary/15 text-primary ring-1 ring-primary/40'
            : 'text-muted-foreground hover:bg-muted hover:text-foreground'
      }`}
    >
      <Icon className="h-[18px] w-[18px] shrink-0" />
      <span className="text-[10px] font-medium leading-tight">{option.label}</span>
    </button>
  )
}

interface ToggleRowProps {
  label: string
  checked: boolean
  onChange: (v: boolean) => void
  disabled?: boolean
  title?: string
}

function ToggleRow({ label, checked, onChange, disabled, title }: ToggleRowProps) {
  return (
    <label
      title={title}
      className={`flex min-h-[34px] items-center justify-between gap-2 rounded-lg px-2 text-[13px] transition-colors ${
        disabled ? 'cursor-not-allowed opacity-50' : 'cursor-pointer hover:bg-muted/50'
      }`}
    >
      <span className="text-muted-foreground">{label}</span>
      <MriSwitch checked={checked} onCheckedChange={onChange} disabled={disabled} size="sm" aria-label={label} />
    </label>
  )
}
