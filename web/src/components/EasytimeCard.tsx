import { useEffect, useRef, type PointerEvent as ReactPointerEvent, type ReactNode } from 'react'
import { MriButton, MriCard, MriCardContent, MriCardFooter, MriSwitch } from '@mriqbox/ui-kit'
import { useEasytime, type EasytimeController } from '@/state/useEasytime'
import { useNuiEvent } from '@/nui/useNuiEvent'
import { formatTime } from '@/lib/time'
import { WEATHER_OPTIONS, type WeatherOption } from './weather'
import { EasytimeSky } from './EasytimeSky'
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

  useEffect(() => {
    if (!visible) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [visible, close])

  const audio = (
    <audio ref={audioRef} src={`${import.meta.env.BASE_URL}sound/tsunami_siren.ogg`} preload="auto" />
  )

  if (!visible) return audio

  return (
    <>
      {audio}
      <div
        ref={dragRef}
        className={`fixed z-50 w-[400px] font-sans ${
          pos ? '' : 'bottom-8 left-1/2 -translate-x-1/2 animate-slide-in-bottom'
        }`}
        style={pos ? { left: pos.x, top: pos.y } : undefined}
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

export function EasytimePanel({ c, onClose, embedded = false, onHandlePointerDown }: PanelProps) {
  const { values } = c
  const weathers = WEATHER_OPTIONS.filter((w) => (w.isNew ? c.show.newWeather : true))
  const fill = ((c.sliderValue - SLIDER_MIN) / (SLIDER_MAX - SLIDER_MIN)) * 100

  return (
    <MriCard
      className={
        embedded
          ? 'flex h-full flex-col rounded-none border-0 bg-transparent font-sans shadow-none'
          : 'overflow-hidden rounded-2xl border-0 font-sans shadow-2xl shadow-black/50'
      }
    >
      {/* Header (céu) — alça de drag só no standalone */}
      <div
        onPointerDown={embedded ? undefined : onHandlePointerDown}
        className={`relative select-none ${embedded ? '' : 'cursor-grab active:cursor-grabbing'}`}
        title={embedded ? undefined : 'Arraste para mover'}
      >
        <EasytimeSky hours={values.hours} mins={values.mins} />
        {!embedded && (
          <div className="absolute left-1/2 top-2.5 h-1 w-9 -translate-x-1/2 rounded-full bg-white/50" />
        )}
      </div>

      <MriCardContent className={`space-y-5 p-5 ${embedded ? 'flex-1 overflow-auto' : ''}`}>
        <div className="-mt-1 text-center text-5xl font-semibold leading-none tracking-tight tabular-nums text-foreground">
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
          <div className="grid grid-cols-2 gap-x-3 gap-y-0.5 rounded-xl bg-muted/30 p-1.5">
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

        {(c.show.realtime || c.show.realweather) && values.real_info?.city && (
          <div className="rounded-xl bg-muted/30 px-3 py-2 text-xs text-muted-foreground">
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
      </MriCardContent>

      <MriCardFooter className="gap-2 px-5 pb-5 pt-0">
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
