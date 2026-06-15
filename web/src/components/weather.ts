import {
  CircleDashed,
  Cloud,
  CloudFog,
  CloudHail,
  CloudLightning,
  CloudRain,
  CloudRainWind,
  CloudSnow,
  CloudSunRain,
  Cloudy,
  Factory,
  Ghost,
  Gift,
  Snowflake,
  Sun,
  SunMedium,
  Wind,
  type LucideIcon,
} from 'lucide-react'
import type { WeatherType } from '@/nui/types'

export interface WeatherOption {
  id: WeatherType
  label: string
  icon: LucideIcon
  /** Climas adicionados em builds recentes (escondidos se game_build < 3258). */
  isNew?: boolean
}

// Um ícone DISTINTO por clima + rótulo (o nome aparece abaixo do ícone na UI).
export const WEATHER_OPTIONS: WeatherOption[] = [
  { id: 'CLEAR', label: 'Limpo', icon: Sun },
  { id: 'EXTRASUNNY', label: 'Ensolarado', icon: SunMedium },
  { id: 'CLOUDS', label: 'Nublado', icon: Cloud },
  { id: 'OVERCAST', label: 'Encoberto', icon: Cloudy },
  { id: 'RAIN', label: 'Chuva', icon: CloudRain },
  { id: 'CLEARING', label: 'Limpando', icon: CloudSunRain },
  { id: 'THUNDER', label: 'Trovoada', icon: CloudLightning },
  { id: 'SMOG', label: 'Poluição', icon: Factory },
  { id: 'FOGGY', label: 'Neblina', icon: CloudFog },
  { id: 'SNOW', label: 'Neve', icon: Snowflake },
  { id: 'SNOWLIGHT', label: 'Neve leve', icon: CloudSnow },
  { id: 'BLIZZARD', label: 'Nevasca', icon: Wind },
  { id: 'HALLOWEEN', label: 'Halloween', icon: Ghost },
  { id: 'XMAS', label: 'Natal', icon: Gift },
  { id: 'NEUTRAL', label: 'Neutro', icon: CircleDashed },
  { id: 'RAIN_HALLOWEEN', label: 'Chuva Halloween', icon: CloudRainWind, isNew: true },
  { id: 'SNOW_HALLOWEEN', label: 'Neve Halloween', icon: CloudHail, isNew: true },
]
