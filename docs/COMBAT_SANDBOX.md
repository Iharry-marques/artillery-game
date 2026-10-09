# Combat Sandbox (Marco 3)

Primeira experiência **jogável**: dois personagens de debug num mapa procedural destrutível, turnos alternados
no mesmo teclado (hot-seat). Não é produção: sem arte, sem itens, sem rede.

## Como jogar

```bash
export GODOT=~/Downloads/Godot.app/Contents/MacOS/Godot   # se o Godot não estiver no PATH nem em /Applications
tools/run_combat_sandbox.sh
```

É a cena principal do projeto: **F5** no editor também abre. O Ballistics Lab continua em `tools/run_ballistics_lab.sh`.

| Tecla | Ação |
|---|---|
| A / D ou ← / → | Andar (só no seu turno, até o orçamento de movimento). Também vira o personagem |
| W / S ou ↑ / ↓ | Ângulo ±1° (segure para repetir). Faixa de entrada 0–90° |
| Segurar ESPAÇO | Carrega a força linearmente (0 → 100) |
| Soltar ESPAÇO | Atira com a força medida |
| R | Reinicia tudo (terreno, jogadores, HP, vento, turno, câmera, toggle de vento 0) |
| Z | Força vento 0 (liga/desliga); útil para testar o Full Throw |
| F3 | Overlay de debug |
| F | **Debug:** Full Throw automático no oponente (força 95, ângulo = 90 − D + 2 × vento relativo, D = distância pé a pé) |

Captura automática (partida roteirizada com screenshots, depois fecha): `tools/run_combat_sandbox.sh --capture=/dir/absoluto`.

## Fluxo de um turno

```
AIMING (andar, mirar) → CHARGING (segurando espaço) → FLIGHT (câmera segue o projétil)
→ RESOLVING (cratera, dano, quedas; câmera parada no impacto por impact_hold_time)
→ próximo jogador: orçamento de movimento renovado, vento novo → AIMING
```

Durante FLIGHT e RESOLVING nenhuma entrada de movimento, mira ou tiro é aceita. Se só restar um jogador vivo, a
partida vai para GAME_OVER ("Player N wins! Press R").

## Balística calibrada × placeholders de playtest

**Calibrado (não mexer sem evidência):** a trajetória vem de `ProjectileSimulation`, com K = 29,033036 u e razão do
vento de 0,034401 (`GameMetrics`). O sandbox só adiciona **onde o voo termina**: o primeiro contato com terreno,
cabeça ou limite do mapa, via `CombatWorldQuery`.

**Placeholders de playtest** (`godot/config/combat_rules.tres`, todos ESTIMATED / GAME DESIGN PLACEHOLDER):

| Grupo | Valor | Observação |
|---|---|---|
| Mapa | 36 × 18 u; células de 0,05 u; chão em y = 12; spawns em x = 13 e 23 (10 u, uma tela); morte em y > 20 | |
| Personagem | cabeça r = 0,25 u com centro 0,65 u acima dos pés; corpo 0,36 × 0,42 u (só visual); altura total ≈ 0,9 u (~16% da altura visível em 16:9) | Proporção de "cabeça grande" do gênero; não medido |
| Cano (OQ-09) | 0,30 u à frente e 0,40 u acima dos pés | Geometria de gameplay; **não** recalibra a balística |
| HP | 100 | |
| Movimento | 1,6 u/s; 4,0 u por turno; rampa máx. 50°; queda a 7 u/s | Sem stamina histórica, sem pulo |
| Mira | 0–90°, passo 1°, inicial 60°, repetição a cada 0,07 s | |
| Força | 0 → 100 em 2,5 s (linear), trava em 100 | OQ-10 |
| Explosão | dano base 35, raio de dano 1,0 u, raio da cratera 0,6 u | Queda linear: `35 × (1 − d/1,0)`, d = distância à borda da cabeça |
| Vento | uniforme em [−2,0; +2,0], passo 0,1, semente 20261006, sorteado a cada turno | OQ-08 |
| Fluxo e câmera | espera no impacto 0,9 s; playback em tempo simulado (×1); suavização da câmera 5/s; pés do jogador ativo a 60% da altura | |

## Geometria: referência balística × cano de gameplay

- **Referência balística (calibração):** o tiro sai de um **ponto**, e o "acerto" é o cruzamento descendente do plano
  na altura de lançamento (D-013). É aí que vale `Ângulo = 90 − D`.
- **Gameplay:** o tiro sai do **cano** (pés + 0,3 u à frente + 0,4 u acima), e o alvo é o **círculo da cabeça**.
  Medindo D pé a pé, o Full Throw cai ~0,3 u mais longe que na calibração. Do spawn (D = 10) com força exata de 95, ele
  ainda acerta a cabeça (teste automatizado), mas a margem é pequena (ver "o que avaliar").

## Arquitetura

```
scripts/core/terrain/terrain_mask.gd          grade de ocupação (lógica pura)
scripts/core/ballistics/                       + BallisticCollisionQuery, BallisticHit, simulate_with_collisions()
scripts/game/combat/                           lógica pura: CombatRules, CombatMatch, CombatantState,
                                               CharacterMotor, CombatWorldQuery, DamageModel, WindGenerator,
                                               ProceduralTestMap
scripts/game/sandbox/                          nós: CombatSandbox (controlador), TerrainView, CombatantView,
                                               ProjectileView, ExplosionView, BattleCamera, SandboxHud,
                                               SandboxMinimap, SandboxDebugOverlay, SandboxInput, SandboxCapture
scripts/presentation/                          compartilhado com o Lab: WorldCanvas, BattleViewFraming, TrajectoryPlayback
scenes/gameplay/combat_sandbox.tscn
```

- **Terreno:** máscara de ocupação (D-025). Consulta sólido/vazio, cratera circular, colisão de segmento por travessia
  exata de células (sem tunelamento), suporte sob os pés, overhangs. O visual é uma textura com um texel por célula.
- **Colisão do projétil:** a simulação gera o passo, e `CombatWorldQuery` testa o segmento entre dois estados contra
  terreno, cabeças vivas e limites (bordas esquerda/direita e linha de morte; o céu é aberto). O contato mais próximo
  vence (D-026).
- **Personagem:** a referência é a FeetAnchor. Três sondas sob os pés (centro e ±0,12 u) encontram o suporte; a queda é
  determinística (D-027).
- **Câmera:** sempre 10 u de largura (`BattleViewFraming`). No turno, enquadra o jogador ativo; no voo, segue o
  projétil, inclusive para fora da tela por cima; depois para no impacto e volta ao próximo jogador.
- **Minimapa:** silhueta amostrada da máscara na mesma escala nos dois eixos, marcadores, projétil e o **retângulo da
  câmera com 10 divisões** (a régua de distância dos jogadores).

## O que avaliar jogando

1. **Duração do voo** (gravidade provisória, ~4 s para um Full Throw): rápido ou lento demais?
2. **Tempo de carga** (2,5 s de 0 a 100): dá para parar em ~95 com consistência? Na captura automática a força saiu
   95,68, e isso já desloca o impacto ~0,14 u a 10 u de distância.
3. **Tamanho da cabeça** (r = 0,25 u) e do personagem em relação à tela de 10 u.
4. **Cratera** (0,6 u) e **dano** (35 no centro, raio 1 u): três acertos diretos matam. Está bom?
5. **Movimento** (4 u/turno, rampa máx. 50°): o morro central, mais íngreme que 50°, bloqueia a passagem, e paredes de
   cratera podem prender um personagem (sem pulo). É o que você espera?
6. **Full Throw a partir do cano:** com wind 0 (Z), 80° e força ~95 do spawn, o tiro deveria acertar ou passar raspando
   a cabeça. Quanto o deslocamento do cano incomoda?
7. **Câmera:** suavização, tempo parado no impacto, enquadramento do jogador ativo.

## Problemas conhecidos

- Bordas do terreno com aparência de degraus (células de 0,05 u ampliadas; filtro linear suaviza só um pouco).
- Uma cratera centrada na cabeça não alcança o chão (0,85 u abaixo): acerto direto não cava sob o alvo.
- O minimapa prende ao topo tudo o que está acima do mapa (projétil alto, retângulo da câmera em voo).
- O HUD tem posições fixas pensadas para 1280×720.
- Valores de ângulo do Full Throw automático fora de 0–90° não disparam (OQ-22).
