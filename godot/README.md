# godot/

Raiz do projeto Godot 4.x (`res://`). Godot usado: 4.7.1-stable. Cena principal provisória: Ballistics Lab.

| Diretório | Conteúdo |
|---|---|
| `scripts/` | GDScript. `core/` (simulação pura, sem Node: balística, métricas, solver de mira); `debug/` (ferramentas de desenvolvimento, ex.: Ballistics Lab); planejado: `game/` (nós de gameplay), `presentation/` (visual, HUD, câmera) |
| `config/` | Recursos de configuração (`game_metrics.tres`). Valores calibrados são gravados pela ferramenta de calibração |
| `calibration/` | Ferramenta de calibração balística (evidência de referência, calibrador, relatório). Não é código de jogo |
| `scenes/` | Cenas `.tscn`. `debug/ballistics_lab.tscn` = Ballistics Lab (docs/BALLISTICS_LAB.md) |
| `assets/` | Assets próprios (placeholders procedurais primeiro, arte do pipeline Blender depois) |
| `shaders/` | Shaders próprios |
| `tests/` | Runner headless próprio (`run_tests.gd`), base `support/test_case.gd`, testes `test_*.gd` |

Comandos (a partir da raiz do repositório): `tools/run_tests.sh`, `tools/ballistics/calibrate.sh` e `tools/run_ballistics_lab.sh`.

Veja [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md).
