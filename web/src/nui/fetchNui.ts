// Ponte NUI → Lua. Equivale ao `post()` do html/js/script.js, que faz
// `fetch("https://cd_easytime/<callback>")`. O nome do recurso é resolvido em
// runtime (GetParentResourceName), com fallback para 'cd_easytime' em dev.

declare const GetParentResourceName: (() => string) | undefined

export function getResourceName(): string {
  // 1) Em modo embedded (iframe dentro do mri_Qadmin) o `GetParentResourceName`
  //    do CEF não é injetado, então derivamos do hostname `cfx-nui-<resource>`,
  //    que é confiável tanto standalone quanto embedded.
  if (typeof window !== 'undefined') {
    const host = window.location.hostname
    if (host.startsWith('cfx-nui-')) return host.slice('cfx-nui-'.length)
  }
  // 2) Fallback: API do CEF (standalone) e, por último, o nome conhecido.
  return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'mri_Qweather'
}

/**
 * Dispara um NUI callback registrado no client.lua (RegisterNUICallback).
 * Callbacks atuais: `close`, `change`, `instanttime`, `instantweather`.
 */
export async function fetchNui<T = unknown>(event: string, data: unknown = {}): Promise<T | null> {
  if (import.meta.env.DEV) {
    // Em dev (navegador) não há host NUI; só logamos a chamada.
    console.debug('[nui →]', event, data)
    return null
  }

  try {
    const resp = await fetch(`https://${getResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    })
    if (!resp.ok) return null
    const text = await resp.text()
    return text ? (JSON.parse(text) as T) : null
  } catch {
    return null
  }
}
