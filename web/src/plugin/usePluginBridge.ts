import { useCallback, useEffect, useRef, useState } from 'react'
import { isMriPluginMessage, type MriPluginGuestMessage, type MriPluginHostMessage } from './types'

interface PluginContext {
  accentColor: string
  backgroundColor: string
  locale: string
  perms: string[]
  initialized: boolean
}

interface Options {
  defaultAccentColor?: string
  defaultLocale?: string
  onClose?: () => void
}

/**
 * Bridge do lado guest (plugin). Manda `ready` no mount, escuta
 * `init`/`theme-changed`/`perms-changed`/`close` do host (Qadmin) e expõe
 * `requestClose`. Em standalone (sem parent) os métodos viram no-op.
 */
export function usePluginBridgeGuest(opts: Options = {}) {
  const { defaultAccentColor = '#00E699', defaultLocale = 'pt-BR', onClose } = opts

  const [context, setContext] = useState<PluginContext>({
    accentColor: defaultAccentColor,
    backgroundColor: '',
    locale: defaultLocale,
    perms: [],
    initialized: false,
  })

  const onCloseRef = useRef(onClose)
  useEffect(() => {
    onCloseRef.current = onClose
  }, [onClose])

  const sendToHost = useCallback((msg: MriPluginGuestMessage): boolean => {
    if (typeof window === 'undefined') return false
    if (window.self === window.top) return false
    window.parent.postMessage(msg, '*')
    return true
  }, [])

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      if (!isMriPluginMessage(event.data)) return
      const msg = event.data as MriPluginHostMessage
      switch (msg.type) {
        case 'mri-plugin/init':
          setContext({
            accentColor: msg.accentColor,
            backgroundColor: msg.backgroundColor ?? '',
            locale: msg.locale,
            perms: msg.perms,
            initialized: true,
          })
          break
        case 'mri-plugin/theme-changed':
          setContext((prev) => ({
            ...prev,
            accentColor: msg.accentColor,
            backgroundColor: msg.backgroundColor ?? prev.backgroundColor,
          }))
          break
        case 'mri-plugin/perms-changed':
          setContext((prev) => ({ ...prev, perms: msg.perms }))
          break
        case 'mri-plugin/close':
          onCloseRef.current?.()
          break
      }
    }
    window.addEventListener('message', onMessage)
    sendToHost({ type: 'mri-plugin/ready' })
    return () => window.removeEventListener('message', onMessage)
  }, [sendToHost])

  const requestClose = useCallback(() => {
    sendToHost({ type: 'mri-plugin/request-close' })
  }, [sendToHost])

  return { ...context, requestClose }
}
