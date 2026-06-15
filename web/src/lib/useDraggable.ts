import { useCallback, useEffect, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'

export interface DragPos {
  x: number
  y: number
}

/**
 * Torna um elemento arrastável. Use `dragRef` no container que se move e
 * `onHandlePointerDown` na "alça" (ex: o cabeçalho). A posição (px, fixed) é
 * mantida em estado, então persiste entre abrir/fechar o painel na sessão.
 */
export function useDraggable() {
  const [pos, setPos] = useState<DragPos | null>(null)
  const dragRef = useRef<HTMLDivElement>(null)
  const dragging = useRef(false)
  const origin = useRef({ mx: 0, my: 0, x: 0, y: 0 })

  const onHandlePointerDown = useCallback(
    (e: ReactPointerEvent<HTMLElement>) => {
      if (e.button !== 0) return // só botão esquerdo
      const el = dragRef.current
      if (!el) return
      const rect = el.getBoundingClientRect()
      origin.current = {
        mx: e.clientX,
        my: e.clientY,
        // Se ainda não foi arrastado, parte da posição atual (centralizada).
        x: pos?.x ?? rect.left,
        y: pos?.y ?? rect.top,
      }
      dragging.current = true
      e.preventDefault()
    },
    [pos],
  )

  useEffect(() => {
    const onMove = (e: PointerEvent) => {
      if (!dragging.current) return
      const el = dragRef.current
      const w = el?.offsetWidth ?? 0
      const h = el?.offsetHeight ?? 0
      const nx = origin.current.x + (e.clientX - origin.current.mx)
      const ny = origin.current.y + (e.clientY - origin.current.my)
      // Mantém o painel dentro da tela.
      setPos({
        x: Math.max(0, Math.min(window.innerWidth - w, nx)),
        y: Math.max(0, Math.min(window.innerHeight - h, ny)),
      })
    }
    const stop = () => {
      dragging.current = false
    }
    window.addEventListener('pointermove', onMove)
    window.addEventListener('pointerup', stop)
    return () => {
      window.removeEventListener('pointermove', onMove)
      window.removeEventListener('pointerup', stop)
    }
  }, [])

  return { pos, dragRef, onHandlePointerDown }
}
