import React from 'react'
import ReactDOM from 'react-dom/client'
import '@mriqbox/ui-kit/dist/style.css'
import './index.css'
import App from './App'
import { startMockNui } from './nui/mockNui'

// Em dev (navegador) simula as mensagens que o client.lua mandaria.
if (import.meta.env.DEV) startMockNui()

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
