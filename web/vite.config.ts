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
    // Hash no nome força o CEF/FiveM a baixar o bundle novo a cada build (sem
    // ele, o NUI fica preso na versão em cache mesmo após restart). O fxmanifest
    // serve `web/build/**/*`, então os nomes com hash são incluídos automaticamente.
    rollupOptions: {
      output: {
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash][extname]',
      },
    },
  },
})
