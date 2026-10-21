# mri_Qweather

Clima e hora da cidade, iguais para todos os jogadores, com painel no tema da suíte MRI.
Tem previsão automática do tempo, clima real de uma cidade, hora real, apagão, alerta de
tsunami antes do restart, clima por zonas do mapa e uma temperatura simulada que outros
resources podem ler.

A versão 3 foi escrita do zero pela MRI.

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `ox_lib` | Sim | Callbacks, notificações e textos |
| `mri_Qadmin` | Não | O painel aparece como aba "Clima" do painel admin MRI |

## Instalação

1. Coloque a pasta `mri_Qweather` em `resources/`.
2. Tire do servidor qualquer outro script de clima e hora (`Renewed-Weathersync`,
   `qb-weathersync`, `vSync`, `cd_easytime`). Dois scripts mexendo no relógio fazem a hora pular.
3. Adicione `ensure mri_Qweather` no `server.cfg`, depois do `ox_lib`.

Pelo instalador da MRI, o script já desativa o `Renewed-Weathersync` sozinho.

Quem atualiza da versão 2 não perde nada: o clima e a hora do `settings.txt` e as zonas do
`data/zones.json` são lidos na primeira subida.

Os Ajustes do painel ficam em `data/settings.json` e as zonas em `data/zones.json`. Os dois
são do dono da cidade: o instalador da MRI guarda eles ao atualizar.

## Painel

`/clima` abre o painel, que também é a aba "Clima" do `mri_Qadmin`. Quem tem a ACE
`command.clima` (todo grupo com `command` liberado) pode abrir. Tudo vale na hora para a
cidade inteira, sem botão de aplicar:

- **Clima e hora**: clima de agora, hora com atalhos, parar o relógio, hora real, clima
  automático pela previsão, clima real, blackout e alerta de tsunami.
- **Previsão**: os próximos climas da previsão automática, para trocar, encurtar ou tirar.
- **Zonas**: áreas desenhadas no mapa e regiões do GTA com clima e temperatura próprios.
- **Ajustes**: duração do dia e da noite, fuso da hora real, troca de clima, frequência de
  cada clima na previsão, chuva, neve em dezembro, cidade e chave do clima real, tsunami,
  faróis no blackout e unidade da temperatura.

Os Ajustes ficam salvos no servidor (KVP), então uma atualização não apaga nada.

## Clima real

Usa a API gratuita do [OpenWeatherMap](https://openweathermap.org/api). Coloque a cidade e
a chave na aba Ajustes; a chave fica só no servidor e nunca vai para os jogadores.

## Comandos

Para staff, com a mesma permissão do painel:

| Comando | O que faz |
|---|---|
| `/clima` | Abre o painel |
| `/time <hora> [minuto]` | Define a hora |
| `/morning`, `/noon`, `/evening`, `/night` | 09:00, 12:00, 18:00 e 23:00 |
| `/weather <tipo>` | Define o clima (`CLEAR`, `RAIN`, `THUNDER`, `SNOW`...) |
| `/timescale <ms>` | Milissegundos reais por minuto de jogo (mínimo 1000) |
| `/freezetime <1\|0>` | Para ou solta o relógio |

## Exports

Client:

```lua
exports.mri_Qweather:GetWeather()         -- { weather, hours, mins, blackout }
exports.mri_Qweather:GetPauseSyncState()  -- sync pausado neste jogador?
exports.mri_Qweather:GetTemperature()     -- temperatura do jogador
exports.mri_Qweather:GetTemperatureData() -- { value, celsius, unit }
exports.mri_Qweather:GetZone()            -- zona de clima em que o jogador está
```

Server:

```lua
exports.mri_Qweather:SetWeather('RAIN')
exports.mri_Qweather:SetTime(22, 30)
exports.mri_Qweather:SetBlackout(true)
exports.mri_Qweather:SetTimeFreeze(true)
exports.mri_Qweather:SetDynamic(false)
exports.mri_Qweather:GetWeather()
exports.mri_Qweather:GetTemperature()
exports.mri_Qweather:GetForecastQueue()
```

## Compatibilidade

Resources feitos para o `qb-weathersync`, o `cd_easytime`, o `vSync` ou o
`Renewed-Weathersync` continuam funcionando sem mudança:

- exports `qb-weathersync` (`setBlackout`, `setWeather`, `setTime`...) e `cd_easytime:GetWeather`;
- eventos `qb-weathersync:client:EnableSync` / `DisableSync`, `vSync:toggle`,
  `cd_easytime:PauseSync` e `qb-weathersync:server:setWeather` / `setTime`;
- `GlobalState` no formato do Renewed: `weather`, `currentTime`, `timeScale`, `freezeTime`, `blackOut`.

## Créditos

- Rodrigo G. Gusmão: o desenho dos efeitos de neve com um dono só e sem `ForceSnowPass`
  (asfalto preto em Los Santos), proposto no [PR #1](https://github.com/mri-Qbox-Brasil/mri_Qweather/pull/1).
- Sirene do tsunami: "Siren Loudspeakers" de Summerson, no
  [freesound.org](https://freesound.org/people/Summerson/sounds/591197/), licença
  [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).
- Caixas das regiões do mapa: tiradas do `popzone.ipl` do GTA V, da Rockstar Games.
- Água da enchente do tsunami (`water/flood.xml`): o `water.xml` do GTA V, da Rockstar Games, com o mar e as ondas da costa trocados por uma grade que cobre o mapa.

## Licença

O código deste recurso é MIT com Commons Clause: pode usar, modificar e redistribuir à vontade, mas não pode vender, nem a versão original nem uma modificada. Texto completo em [LICENSE](LICENSE).

O som da sirene e os dados do mapa do GTA V são dos seus criadores e não entram nessa licença. Se você é autor de algum deles e quer que seja removido, é só abrir uma [issue](https://github.com/mri-Qbox-Brasil/mri_Qweather/issues) que a gente tira.
