# godot/

Raiz do projeto Godot 4.x (`res://`). Godot usado: 4.7.1-stable. Cena principal: Combat Sandbox (jogável).

| Diretório | Conteúdo |
|---|---|
| `scripts/` | GDScript. `core/` (simulação pura, sem Node: balística, métricas, solver de mira); `core/terrain/` (máscara de terreno); `game/combat/` (regras de combate puras); `game/sandbox/` (nós do sandbox); `presentation/` (auxiliares de desenho compartilhados); `debug/` (Ballistics Lab) |
| `config/` | `game_metrics.tres` (balística calibrada, gravada pela ferramenta) e `combat_rules.tres` (placeholders de playtest) |
| `calibration/` | Ferramenta de calibração balística (evidência de referência, calibrador, relatório). Não é código de jogo |
| `scenes/` | Cenas `.tscn`. `gameplay/combat_sandbox.tscn` = Combat Sandbox (docs/COMBAT_SANDBOX.md); `debug/ballistics_lab.tscn` = Ballistics Lab (docs/BALLISTICS_LAB.md) |
| `assets/` | Assets próprios (placeholders procedurais primeiro, arte do pipeline Blender depois) |
| `shaders/` | Shaders próprios |
| `tests/` | Runner headless próprio (`run_tests.gd`), base `support/test_case.gd`, testes `test_*.gd` |

Comandos (a partir da raiz do repositório): `tools/run_combat_sandbox.sh`, `tools/run_tests.sh`, `tools/ballistics/calibrate.sh` e `tools/run_ballistics_lab.sh`.

Veja [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md).
