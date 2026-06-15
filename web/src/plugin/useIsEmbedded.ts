// Detecta se rodamos dentro do mri_Qadmin (embedded) ou standalone (NUI própria
// aberta via /clima).
//
// IMPORTANTE: NÃO usar `window.self !== window.top` no FiveM — toda NUI já roda
// dentro de um iframe do CEF, então isso daria true mesmo em standalone. O sinal
// confiável é o query param `?embedded=1` que o Qadmin injeta na URL do iframe.

export const useIsEmbedded = (): boolean => {
  if (typeof window === 'undefined') return false
  return new URLSearchParams(window.location.search).get('embedded') === '1'
}
