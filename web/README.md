# cd_easytime — NUI em React

Reescrita da interface do `cd_easytime` em **React + TypeScript + Vite**, usando o
**[@mriqbox/ui-kit](https://github.com/mri-Qbox-Brasil/mri-ui-kit)**.

A UI antiga em `html/` (Bootstrap/jQuery) foi **removida** e substituída por esta
versão React. O lado Lua **não mudou** — o contrato NUI é o mesmo.

## Estrutura

```
web/
├── index.html              # shell do NUI (<html class="dark">)
├── vite.config.ts          # base: './'  +  build → web/build
├── tailwind.config.js      # tema espelhado do mri-ui-kit
├── src/
│   ├── main.tsx            # entrypoint (importa o CSS do kit + o nosso)
│   ├── App.tsx
│   ├── index.css           # @tailwind + variáveis de tema + fundo transparente
│   ├── nui/
│   │   ├── types.ts        # tipos do objeto `values` (contrato com o Lua)
│   │   ├── fetchNui.ts     # NUI → Lua  (equivale ao post() do script.js)
│   │   ├── useNuiEvent.ts  # Lua → NUI  (equivale ao window 'message')
│   │   └── mockNui.ts      # simula o client.lua no navegador (pnpm dev)
│   ├── lib/time.ts         # numToTime / convertTime / formatTime
│   ├── state/useEasytime.ts# todo o estado + regras (portado do script.js)
│   └── components/
│       ├── EasytimeCard.tsx
│       ├── EasytimeSky.tsx # sol/lua + nuvens/estrelas animados
│       └── weather.ts      # 17 climas → ícones Lucide
└── public/sound/           # tsunami_siren.ogg + attribution.txt
```

## Desenvolvimento

```bash
cd web
pnpm install
pnpm dev          # abre no navegador; o mockNui dispara o 'open' automaticamente
```

No console do navegador dá pra testar: `easytimeMock.open({ weather: 'RAIN', hours: 22 })`,
`easytimeMock.close()`, `easytimeMock.playsound()`.

## Build para o jogo

```bash
cd web
pnpm build        # gera web/build/  (index.html + assets/)
```

## Integração no fxmanifest (já aplicada)

```lua
ui_page 'web/build/index.html'
files {
    'web/build/index.html',
    'web/build/**/*',
}
```

> Após mudar o fonte: `pnpm -C web build` e depois `restart cd_easytime` no servidor.

## Pontos de atenção

- **`base: './'` é obrigatório** — sem isso os assets quebram no esquema `nui://`.
- **Fonte Saira:** hoje vem do Google Fonts (`@import` no `index.css`). Em servidores
  sem internet no cliente, baixe a fonte e sirva localmente.
- **Ícones de clima:** são uma aproximação em Lucide (`weather.ts`); ajuste à vontade.
  Casos especiais (`HALLOWEEN`, `XMAS`, `NEUTRAL`, `*_HALLOWEEN`) não têm equivalente 1:1.
- **Escrow:** ao empacotar, garanta que `web/build/**` entre nos arquivos do recurso.
