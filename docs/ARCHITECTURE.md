# Arquitetura (conceitual)

> Fronteiras e responsabilidades. Nomes de classes em inglês (código).
> **Implementado no Marco 1:** `GameMetrics`, `ProjectileSimulation` (+ estado, integrador, modelo de força, parâmetros,
> resultado) e o solver inverso de mira. O restante é só desenho.
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

`calibration/` e `tests/` dependem de `core/`; o `core/` não depende deles. Os dados de evidência
(`BallisticEvidence`) nunca são lidos pela física.

## 6. Fora do escopo (decisão explícita necessária para entrar)

Networking, backend, contas, matchmaking, persistência online, monetização, sistema de atributos de RPG,
itens e mascotes.
