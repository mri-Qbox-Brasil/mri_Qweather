import { usePluginBridgeGuest } from '@/plugin/usePluginBridge'
import { useAccentColor, useBackgroundColor } from '@/lib/color'
import { useEasytime } from '@/state/useEasytime'
import { EasytimePanel } from './EasytimeCard'

// Modo embedded: hospedado pelo mri_Qadmin (aba "Clima"). O tema vem do bridge
// (postMessage), o estado vem do getState (dentro do useEasytime), e "Fechar"
// pede ao host pra fechar a UI.
export function EmbeddedApp() {
  const bridge = usePluginBridgeGuest({ defaultAccentColor: '#00E699' })
  useAccentColor(bridge.accentColor)
  useBackgroundColor(bridge.backgroundColor)

  const c = useEasytime({ embedded: true })

  if (!c.visible) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-background font-sans text-sm text-muted-foreground">
        Carregando…
      </div>
    )
  }

  return (
    <div className="h-full w-full overflow-hidden bg-background text-foreground">
      <EasytimePanel c={c} embedded onClose={bridge.requestClose} />
    </div>
  )
}
