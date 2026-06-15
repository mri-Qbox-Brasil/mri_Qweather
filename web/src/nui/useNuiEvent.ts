import { useEffect, useRef } from 'react'

// Ponte Lua → NUI. Equivale ao `window.addEventListener("message", ...)` do
// html/js/script.js. O client.lua usa SendNUIMessage({action = '...', ...}).

type Handler<T> = (data: T) => void

export function useNuiEvent<T = unknown>(action: string, handler: Handler<T>): void {
  const saved = useRef<Handler<T>>(handler)

  useEffect(() => {
    saved.current = handler
  }, [handler])

  useEffect(() => {
    const listener = (event: MessageEvent) => {
      const payload = event.data as { action?: string } | undefined
      if (payload?.action === action) {
        saved.current(event.data as T)
      }
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [action])
}
