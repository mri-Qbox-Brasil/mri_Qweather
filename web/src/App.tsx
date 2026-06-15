import { EasytimeCard } from './components/EasytimeCard'
import { EmbeddedApp } from './components/EmbeddedApp'
import { useIsEmbedded } from './plugin/useIsEmbedded'

export default function App() {
  const embedded = useIsEmbedded()
  return embedded ? <EmbeddedApp /> : <EasytimeCard />
}
