# mri_Qweather

Clima e hora da cidade, sincronizados para todos os jogadores, com painel no tema da
suíte MRI. Controla o ciclo do dia, a fila de previsão do tempo, apagão, clima por
zonas do mapa e uma temperatura simulada que outros resources podem ler.

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `ox_lib` | Sim | Callbacks e notificações |
| `qbx_core` | Sim | Framework e permissões (grupos `god` e `admin`) |
| `mri_Qadmin` | Não | Registra o painel como aba "Clima" do painel admin MRI |

## Instalação

1. Coloque a pasta `mri_Qweather` em `resources/`.
2. Tire do servidor qualquer outro script de clima e hora (`Renewed-Weathersync`,
   `qb-weathersync`, `vSync`). Dois scripts mexendo no relógio fazem a hora pular.
3. Adicione `ensure mri_Qweather` no `server.cfg`, depois do `ox_lib` e do `qbx_core`.

Pelo instalador da MRI, o script já desativa o `Renewed-Weathersync` sozinho.

## Painel

`/clima` abre o painel (ou a aba "Clima" do `mri_Qadmin`). Por ele dá pra:

- trocar o clima e a hora, com ou sem transição suave;
- congelar a hora e ajustar a velocidade do dia e da noite separadamente;
- ligar e desligar o clima dinâmico e ver a fila de previsão;
- ligar o apagão;
- criar e editar zonas de clima no jogo.

Quem pode abrir é definido em `Config.Permissions` (`configs/config.lua`): grupos do
framework, identifiers, ACE ou cargos do Discord.

## Comandos

Para staff, com a mesma permissão do painel:

| Comando | O que faz |
|---|---|
| `/time <hora> [minuto]` | Define a hora sem transição |
| `/noon`, `/morning`, `/evening`, `/night` | 12:00, 09:00, 18:00 e 23:00 |
| `/weather <tipo>` | Define o clima (`CLEAR`, `RAIN`, `THUNDER`, `SNOW`...) |
| `/timescale <ms>` | Milissegundos reais por minuto de jogo (mínimo 1000) |
| `/freezetime <1\|0>` | Congela ou solta a hora |

## Hora

`Config.Time.METHOD` escolhe a fonte:

- `game`: relógio próprio do servidor. `time_cycle_speed` e `night_cycle_speed` são os
  segundos reais por minuto de jogo, de dia e de noite.
- `real`: hora de uma cidade real (precisa de `Config.APIKey` do OpenWeatherMap).

## Clima por zonas

O clima do GTA é um só na tela. Ao entrar numa zona, o jogador passa a ver o clima da
zona no lugar do clima global:

- **Zonas nativas** do GTA (ex.: `MTCHIL`, Mount Chiliad), em `Config.Zones.natives`.
- **Zonas próprias** em círculo, criadas e editadas no painel. Ficam salvas em
  `data/zones.json`.

Cada zona pode forçar um clima (`fixed`) ou só aceitar alguns e trocar o resto
(`bias`), e pode somar graus à temperatura (`tempMod`).

## Temperatura

O GTA não tem temperatura. O script calcula uma pelo clima, pela hora e pelo mês, e
cada jogador ainda recebe o ajuste da altitude, da água e da zona onde está. Ele só
expõe o valor: quem quiser usar (HUD, status, roupas) lê pelos exports.

## Exports

Client:

```lua
exports.mri_Qweather:GetWeather()        -- clima atual
exports.mri_Qweather:GetAllData()        -- clima, hora e flags
exports.mri_Qweather:GetPauseSyncState() -- sync pausado neste client?
exports.mri_Qweather:GetTemperature()    -- temperatura do jogador
exports.mri_Qweather:GetTemperatureData()
exports.mri_Qweather:GetZone()           -- zona de clima em que o jogador está
```

## Compatibilidade

Resources feitos para o `qb-weathersync` ou o `Renewed-Weathersync` continuam
funcionando: os exports `qb-weathersync`, os eventos `qb-weathersync:*` e `vSync:toggle`
e o `GlobalState` (`weather`, `currentTime`, `timeScale`, `freezeTime`, `blackOut`) são
atendidos por este script.

## Arquivos que o servidor grava

- `settings.txt`: último clima, hora e opções do painel.
- `data/zones.json`: zonas criadas no jogo.

Ao atualizar, guarde esses dois (o instalador da MRI já guarda).

## Créditos e licença

Baseado no Easytime da Codesign. Distribuído sob a licença
[CC BY-NC-SA 4.0](LICENSE.md): uso livre, sem fins comerciais, mantendo a mesma licença.
