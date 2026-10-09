# Arquitetura (conceitual)

> Fronteiras e responsabilidades. Nomes de classes em inglês (código).
> **Implementado no Marco 1:** `GameMetrics`, `ProjectileSimulation` (+ estado, integrador, modelo de força, parâmetros,
> resultado) e o solver inverso de mira. **Marco 2:** Ballistics Lab (ferramenta de debug, seção 7). **Marco 3:** Combat
> Sandbox jogável (seção 8): terreno, personagens, colisão, dano, turnos, câmera, HUD e minimapa em versão placeholder.
> Última revisão: 06/10/2026.

## 1. Camadas

```
┌───────────────────────────────────────────────────────────────┐
│ presentation/   CameraController · BattleHUD · Minimap ·      │  lê estado, emite input
│                 placeholders visuais · efeitos                 │  nunca decide gameplay
├───────────────────────────────────────────────────────────────┤
│ game/           TurnManager · Character · Terrain ·           │  nós Godot, orquestração,
│                 Projectile (nó) · ExplosionSystem ·           │  sinais
│                 DamageSystem · WindSystem · AimingSystem      │
├───────────────────────────────────────────────────────────────┤
│ core/           GameMetrics · WeaponDefinition ·              │  GDScript puro (RefCounted/
│                 ProjectileSimulation · DistanceMeasure ·      │  Resource), sem Node,
│                 AimingTechnique (preditores)                  │  testável em headless
└───────────────────────────────────────────────────────────────┘
tools/ e godot/tests/ usam core/ diretamente.
```

Regra de dependência: `presentation → game → core`. O `core` não conhece nós, cenas, câmera nem resolução.

## 2. Sistemas

| Sistema | Camada | Responsabilidade | Não faz |
|---|---|---|---|
| **GameMetrics** | core | Constantes centralizadas (unidade de distância, gravidade, `power_scale`, vento, dt, largura da câmera em u). Um `Resource` (`.tres`) versionado, com origem de cada valor em GAME_METRICS.md | Lógica |
| **WeaponDefinition** | core | Dados por arma: limites de ângulo, raio de explosão, raio de cratera, dano base, multiplicadores futuros | Simular voo |
| **ProjectileSimulation** | core | Integra a trajetória com passo fixo, a partir de (origem, ângulo, força, facing, vento, metrics). Função pura `step(state) → state` + `simulate(until_collision)`. Recebe um *callback/consulta de colisão* abstrato | Saber o que é terreno, tocar nós, aplicar dano |
| **DistanceMeasure** | core | Converte coordenadas de mundo em unidades de distância (horizontal e desnível) | Depender da tela |
| **AimingTechnique** | core | Descreve uma estratégia humana (força fixa, regra ângulo-distância, fator de vento). Serve a testes, ao Lab e a dicas futuras | **Jamais** alterar a trajetória |
| **Projectile** | game | Nó que avança a `ProjectileSimulation` no `_physics_process`, consulta o Terrain/Characters para colisão por segmento e emite `impacted(point)` | Calcular física própria |
| **AimingSystem** | game | Estado de mira do personagem ativo: ângulo (passo de 1°, limites da arma), carga da força, disparo | Prever trajetória |
| **WindSystem** | game | Gera e mantém o vento do turno (constante durante o voo, muda entre turnos), de forma determinística por seed | Aplicar força (quem aplica é a simulação) |
| **Character** | game | Posição, facing, HP, hitbox, movimento sobre o terreno, queda | Desenhar a si mesmo (composição com nó visual) |
| **Terrain** | game | Geometria destrutível, consulta de colisão, subtração de cratera, consulta de "chão" para personagens | Calcular dano |
| **ExplosionSystem** | game | Converte impacto em evento de explosão: cratera no Terrain, consulta de entidades no raio | Fórmula de dano |
| **DamageSystem** | game | Fórmula de dano (decaimento radial etc.), aplica no HP | Geometria |
| **TurnManager** | game | Máquina de estados da batalha: TURN_START → MOVE/AIM → CHARGE → FLIGHT → RESOLVE → TURN_END; ordem de turno; condição de vitória | Input bruto, câmera |
| **CameraController** | presentation | Segue o personagem ativo e o projétil; **mantém a largura visível = 10 u** (zoom derivado do viewport) | Influenciar a física |
| **BattleHUD** | presentation | Ângulo, força, vento, HP, turno | Guardar estado de gameplay |
| **Minimap** | presentation | Mapa reduzido + retângulo da câmera (instrumento de medição em 10 divisões) | Medir distância por conta própria (usa DistanceMeasure) |

## 3. Fluxo de um tiro

```
AimingSystem (ângulo, força) ─fire─▶ TurnManager ─▶ Projectile(node)
                                                        │ cada tick fixo
                                                        ▼
                                        ProjectileSimulation.step()
                                                        │ segmento p0→p1
                                                        ▼
                                  Terrain / Characters (consulta de colisão)
                                                        │ impacto
                                                        ▼
                         ExplosionSystem ─▶ Terrain.carve()  +  DamageSystem.apply()
                                                        │
                                                        ▼
                                            TurnManager → próximo turno → WindSystem
```

## 4. Princípios

- **Uma simulação, muitas técnicas.** `AimingTechnique` só prevê. Os testes usam técnicas para afirmar que a
  física se comporta como os jogadores esperavam.
- **Simulação independente do Godot Physics.** A trajetória não usa RigidBody2D, `linear_damp`, gravidade do
  projeto nem `delta` variável. O nó apenas avança ticks fixos.
- **Mesma simulação no jogo, no Lab e nos testes.** Nada de "preview" com fórmula analítica diferente da real.
- **Dados em Resources.** GameMetrics e WeaponDefinition são `.tres` versionados; nada de constantes soltas em scripts.
- **Composição.** Character = corpo + componente de mira + componente de HP + nó visual separado.
- **Sinais para desacoplar.** Sistemas de jogo emitem eventos (`shot_fired`, `impacted`, `turn_changed`);
  a apresentação escuta.

## 5. Mapeamento de diretórios (`godot/`)

```
scripts/core/game_metrics.gd           ✔ constantes centralizadas
scripts/core/ballistics/               ✔ projectile_simulation, projectile_state, ballistic_integrator,
                                         exact_kinematic_integrator, power_model, linear_power_model,
                                         shot_parameters, ballistic_parameters, ballistic_result
scripts/core/aiming/                   ✔ ballistic_solver (perguntas inversas, só previsão)
                                         planejado: aiming_technique
scripts/core/                          planejado: weapon_definition, distance_measure
scripts/game/                          planejado: projectile, aiming_system, wind_system, character, terrain,
                                         explosion_system, damage_system, turn_manager
scripts/presentation/                  planejado: camera_controller, battle_hud, minimap
config/                                ✔ game_metrics.tres; planejado: weapons/*.tres
calibration/                           ✔ ballistic_evidence, ballistic_calibrator, calibrate (ferramenta, não jogo)
tests/                                 ✔ run_tests.gd, support/, test_*.gd
scenes/                                planejado: lab/ (Ballistics Lab), battle/
```

scripts/core/terrain/                  ✔ terrain_mask (grade de ocupação)
scripts/game/combat/                   ✔ lógica pura de combate (seção 8)
scripts/game/sandbox/                  ✔ nós do Combat Sandbox (seção 8)
scripts/presentation/                  ✔ WorldCanvas, BattleViewFraming, TrajectoryPlayback (Lab + Sandbox)
config/combat_rules.tres               ✔ placeholders de playtest (CombatRules)
scenes/gameplay/combat_sandbox.tscn    ✔ cena principal
scripts/debug/ballistics_lab/          ✔ Ballistics Lab (seção 7)
scenes/debug/ballistics_lab.tscn       ✔ cena do Lab (cena principal do projeto por enquanto)

`calibration/`, `tests/` e `debug/` dependem de `core/`; o `core/` não depende deles. Os dados de evidência
(`BallisticEvidence`) nunca são lidos pela física.

## 6. Fora do escopo (decisão explícita necessária para entrar)

Networking, backend, contas, matchmaking, persistência online, monetização, sistema de atributos de RPG,
itens e mascotes.

## 7. Ballistics Lab (Marco 2, ferramenta de debug)

```
BallisticsLab (Control, orquestra)                      scripts/debug/ballistics_lab/
├── Layout/WorldView (SubViewportContainer)
│   └── WorldViewport/World
│       ├── WorldGrid            LabWorldGrid           régua 1 / 5 / 10 u, y = 0, rótulos
│       ├── TrajectoryRenderer   LabTrajectoryRenderer  desenha amostras do BallisticResult
│       ├── ShooterMarker        LabReferenceMarker     ponto de referência (0, 0)
│       ├── TargetMarker         LabReferenceMarker     (facing·D, target y)
│       ├── PlaybackMarker       LabPlaybackMarker      replay por sample_times
│       └── DebugCamera          LabDebugCamera         BATTLE / FOLLOW / FIT
└── Layout/Panel                 LabPanel               leitura + controles
Lógica pura (testável sem cena): LabShotSetup, LabScenarios, LabAimingTools,
TrajectoryPlayback, BattleViewFraming, LabResultFormatter, LabView.
```

- `LabShotSetup.simulate()` chama `ProjectileSimulation.simulate_to_plane()` com o plano na altura do alvo. É a única
  fonte de trajetória do Lab.
- Helpers de mira só chamam `BallisticEvidence` / `BallisticSolver`.
- A largura de 10 u vem de `GameMetrics.battle_view_width_units`; o zoom é derivado do tamanho do viewport do mundo.
- `LabCapture` (`--capture=<dir>`) percorre cenários e câmeras, imprime os números e salva PNGs (revisão visual).

## 8. Combat Sandbox (Marco 3)

| Sistema planejado (seção 2) | Implementação no sandbox | Camada |
|---|---|---|
| Terrain | `TerrainMask` (core) + `ProceduralTestMap` + `TerrainView` | core / game / nó |
| ProjectileSimulation + colisão | `simulate_with_collisions` + `BallisticCollisionQuery` → `CombatWorldQuery` | core / game |
| Projectile | `ProjectileView` (playback das amostras; sem física própria) | nó |
| Character | `CombatantState` + `CharacterMotor` + `CombatantView` | game / nó |
| ExplosionSystem + DamageSystem | `CombatMatch._resolve_impact` + `DamageModel` + `ExplosionView` | game / nó |
| WindSystem | `WindGenerator` | game |
| AimingSystem | pedidos de `CombatMatch` (`request_angle_step`, `request_begin_charge`, `request_release`) | game |
| TurnManager | `CombatMatch` (máquina de estados) | game |
| CameraController | `BattleCamera` | nó |
| BattleHUD / Minimap | `SandboxHud` / `SandboxMinimap` | nó |
| — | `CombatSandbox` (input → pedidos, câmera, sinais → views), `SandboxDebugOverlay`, `SandboxCapture` | nó |

Fluxo de dados: input → `CombatMatch.request_*` → `_fire()` roda a simulação inteira contra o mundo congelado →
`FLIGHT` avança `flight_elapsed` (as views fazem o playback) → `_resolve_impact()` cava a cratera e aplica dano
(sinais `terrain_changed` e `impact_resolved` → views) → `_settle()` faz as quedas → `_end_turn()`.

## 9. Battle Reference Clone (Marco 4)

Mesma lógica da seção 8; só a apresentação mudou.

```
CombatSandbox (Node2D)
├── Background (Node)            BattleBackground: céu + parallax manual em CanvasLayers
├── World (Node2D)
│   ├── TerrainView (Sprite2D)   shader terrain.gdshader sobre a máscara (r/g/b)
│   ├── Player1, Player2         CombatantView = CharacterRoot
│   │   ├── Visual (espelhado)   Body (sprite) · WeaponPivot → Weapon (sprite, gira no ângulo)
│   │   └── Head                 HeadHitbox (marcador; desenhado pelo F2)
│   ├── Projectile               sprite + rastro a partir das amostras
│   ├── Explosion                flash, fogo, fumaça, detritos, números de dano
│   ├── HitboxOverlay (F2)       hitbox × arte, pés, pivô, lançamento, vetor de mira
│   ├── DebugOverlay (F3)
│   └── BattleCamera             10 u; suavização por fase; zona morta; tremor visual
└── Hud (CanvasLayer)            SandboxHud: cards, vento, minimapa, mostrador, força, status, banner
```

- `CharacterProxyArt` (`scripts/presentation/`) lê `proxy_meta.json` e os PNGs gerados por `tools/blender/`.
- `MinimapProjection` (`scripts/presentation/`): transformação mundo→minimapa com uma única escala (testada).
- Geometria de gameplay nova em `CombatantState`: `weapon_pivot_*`, `muzzle_*(angle)` (ponta do cano), `is_inside_head`.
- `CombatWorldQuery` recebe o atirador para ignorar a própria cabeça até o projétil sair dela.

## 10. Product Shell (Marco 5)

```
scripts/meta/      domínio headless: PlayerProfile, Inventory, EquipmentLoadout, CurrencyWallet, Progression,
                   CharacterStats, EnhancementRules, Blacksmith, ShopService, RoomState, RewardCalculator,
                   SaveService, ContentCatalog/ContentDatabase, GameSession (singleton estático)
scripts/shell/     UiKit (tema), ShellScreen (base), ScreenRouter, DisplayControl (autoload DisplayManager),
                   widgets/ (TopBar, ItemSlot, ItemIcon, CharacterPreview, ModalWindow, Toast, CityBuilding)
                   screens/ (uma tela por script; cenas em scenes/shell/*.tscn)
scripts/game/combat/  BattleSetup → CombatMatch (times, loadouts, estágios), CombatLoadout, DamageFormula,
                      ArtilleryPlanner; BattleOutcome volta para GameSession.finish_battle
scripts/game/sandbox/ cena de batalha (modo sandbox ou batalha), AiTurnDriver
scripts/debug/shell_capture.gd  revisão visual automatizada do produto
```

- Fluxo: tela → `GameSession` (regra + autosave) → tela. Telas não calculam regras.
- Batalha: tela define `pending_battle` → `ScreenRouter.go(&"battle")` → cena joga → `finish_battle(outcome)` → `result`.
- A simulação balística, a câmera de 10 u e a separação gameplay/apresentação seguem iguais. Detalhes em
  [PRODUCT_SHELL.md](PRODUCT_SHELL.md).

