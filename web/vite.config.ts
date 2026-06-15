import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// ⚠️ NUI do FiveM serve os arquivos pelo esquema `nui://`, então TODOS os assets
// precisam ser referenciados por caminho RELATIVO. `base: './'` garante isso —
// sem ele, o bundle aponta para `/assets/...` e a tela fica em branco no jogo.
//
// O build sai em `web/build`. O recurso passa a servir essa pasta via fxmanifest
// (ver instruções no web/README.md). Para desenvolver no navegador use `pnpm dev`.
export default defineConfig({
  plugins: [react()],
  base: './',
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    outDir: 'build',
    emptyOutDir: true,
    // Nomes estáveis (sem hash) deixam o whitelist de `files{}` no fxmanifest simples.
    rollupOptions: {
      output: {
        entryFileNames: 'assets/[name].js',
        chunkFileNames: 'assets/[name].js',
        assetFileNames: 'assets/[name][extname]',
      },
    },
  },
})
