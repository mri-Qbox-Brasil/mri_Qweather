import { useEffect } from 'react'

// Sistema de cores da suite MRI. A cor de destaque vem da convar `mri:color`
// e a de fundo de `mri:backgroundColor`. Aqui convertemos hex → HSL e setamos
// as variáveis de tema do mri-ui-kit. Portado do mri_Qspawn.

function hexToHsl(hex: string): { h: number; s: number; l: number } | null {
  const m = hex.match(/^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})?$/i)
  if (!m) return null
  const r = parseInt(m[1], 16) / 255
  const g = parseInt(m[2], 16) / 255
  const b = parseInt(m[3], 16) / 255
  const max = Math.max(r, g, b)
  const min = Math.min(r, g, b)
  let h = 0
  let s = 0
  const l = (max + min) / 2
  if (max !== min) {
    const d = max - min
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
    if (max === r) h = (g - b) / d + (g < b ? 6 : 0)
    else if (max === g) h = (b - r) / d + 2
    else h = (r - g) / d + 4
    h *= 60
  }
  return { h: Math.round(h), s: Math.round(s * 100), l: Math.round(l * 100) }
}

/** Aplica a cor de destaque (mri:color) em --primary e --ring. */
export function applyAccentColor(hex: string | undefined): void {
  if (!hex) return
  const hsl = hexToHsl(hex)
  if (!hsl) return
  const value = `${hsl.h} ${hsl.s}% ${hsl.l}%`
  const root = document.documentElement
  root.style.setProperty('--primary', value)
  root.style.setProperty('--ring', value)
}

const BG_VARS = [
  '--background',
  '--card',
  '--popover',
  '--secondary',
  '--muted',
  '--border',
  '--input',
  '--foreground',
  '--card-foreground',
  '--popover-foreground',
] as const

/** Recolore o fundo a partir de mri:backgroundColor. Vazio = volta ao tema padrão. */
export function applyBackgroundColor(hex: string | undefined): void {
  const root = document.documentElement
  if (!hex) {
    BG_VARS.forEach((v) => root.style.removeProperty(v))
    return
  }
  const hsl = hexToHsl(hex)
  if (!hsl) return
  const { h, s, l } = hsl
  root.style.setProperty('--background', `${h} ${s}% ${l}%`)
  root.style.setProperty('--card', `${h} ${s}% ${Math.min(l + 2, 100)}%`)
  root.style.setProperty('--popover', `${h} ${s}% ${Math.min(l + 2, 100)}%`)
  const surf = `${h} ${Math.max(s - 5, 0)}% ${Math.min(l + 11, 100)}%`
  ;(['--secondary', '--muted', '--border', '--input'] as const).forEach((v) => root.style.setProperty(v, surf))
  const fg = l < 50 ? '0 0% 98%' : '240 10% 3.9%'
  ;(['--foreground', '--card-foreground', '--popover-foreground'] as const).forEach((v) =>
    root.style.setProperty(v, fg),
  )
}

export function useAccentColor(hex: string | undefined): void {
  useEffect(() => applyAccentColor(hex), [hex])
}

export function useBackgroundColor(hex: string | undefined): void {
  useEffect(() => applyBackgroundColor(hex), [hex])
}
