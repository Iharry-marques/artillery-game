# Progresso

Diário de engenharia. Entrada mais recente no topo.

---

## 06/10/2026 · Marco 1: núcleo balístico headless

**Feito**
- Godot 4.7.1-stable (official) validado em `~/Downloads/Godot.app`; projeto mínimo em `godot/project.godot`, sem cena.
- Simulação pura em `godot/scripts/core/ballistics/` (estado, integrador exato, modelo de força isolado, parâmetros,
  resultado, `ProjectileSimulation`). `GameMetrics` + `config/game_metrics.tres`. Solver inverso em `scripts/core/aiming/`.
- Calibração reproduzível: `tools/ballistics/calibrate.sh` → `godot/calibration/` → relatório em
  `tools/ballistics/reports/calibration_report.md`.
- Resultados: K = 29,033036 u (= forma fechada, Δ 2e-10); Full Throw D = 1…10 com erro médio 0,0316 u e máx. 0,0701 u;
  vento 0,034401·g por unidade (correção 1,976°–2,035°); invariância de timestep ≤ 1,5e-13 u; previsões para 20°/30°/50°/65°
  e Half Throw registradas (PHYSICS_MODEL §10–11).
- Bug encontrado e corrigido na causa: subida e descida dentro de um único passo eram tratadas como `NO_ASCENT`
  (dependente do dt). Teste de regressão adicionado.
- Testes: runner próprio + checagem estática estrita. `tools/run_tests.sh` → 20 passed, 0 failed. Também foi verificado
  que o comando retorna código ≠ 0 com métricas não calibradas (18 falhas), erro de runtime de script e warning de tipagem.
- Docs atualizados: PHYSICS_MODEL (reescrito), GAME_METRICS, EVIDENCE_MATRIX, OPEN_QUESTIONS, DECISIONS (D-012 a D-018),
  GAMEPLAY_KNOWLEDGE, ARCHITECTURE, CLAUDE.md, READMEs.

**Não feito (de propósito)**
- Ballistics Lab visual, personagens, terreno, HUD, minimapa, armas, explosões, turnos, câmera, assets.

**Pendências / observações**
- O Godot está em `~/Downloads`; os scripts o encontram via `GODOT=...` (ou mova para `/Applications`).
- Escala de tempo (gravidade) segue ESTIMATED / LOW (4 s de voo provisórios).

---

## 06/10/2026 · Marco 0: fundação documental

**Feito**
- Repositório inspecionado: git inicializado sem commits; único conteúdo era `research/DDTANK_DEEP_RESEARCH.md`.
- Estrutura criada: `docs/`, `godot/{assets,scenes,scripts,shaders,tests}`, `blender/{characters,weapons,environments}`,
  `tools/{ballistics,capture,blender}`. `blender/scripts/` foi descartado em favor de `tools/blender/` (D-007).
- Documentação: CLAUDE.md, README.md, .gitignore, GAME_VISION, GAMEPLAY_KNOWLEDGE, EVIDENCE_MATRIX, GAME_METRICS,
  PHYSICS_MODEL, ARCHITECTURE, DECISIONS, OPEN_QUESTIONS, PROGRESS; READMEs de `research/`, `godot/`, `tools/`, `blender/`.
- Avaliação de confiabilidade da pesquisa existente (baixa a média; contradições internas listadas).
- Análise analítica do modelo balístico candidato (Python, fora do repositório):
  - `Ângulo = 90 − D` com força fixa surge de balística sem arrasto quando `v(95)²/g ≈ 28,65–29,03 u`.
  - Vento ×2 no Full Throw ⇒ `a_vento ≈ g/28,65` por unidade.
  - O mesmo modelo prevê o ×1 da técnica de 30° sem calibração adicional.

**Não feito (de propósito)**
- Nenhum gameplay, arte, Ballistics Lab, `project.godot` ou download de imagens.

**Bloqueios / ambiente**
- Godot e Blender não instalados nesta máquina em 06/10/2026.
- Commit inicial publicado depois em https://github.com/Iharry-marques/artillery-game (45c5c56).

**Próximo**
- Marco 1: núcleo balístico headless (instalar Godot, `project.godot`, GameMetrics, ProjectileSimulation pura, solver de calibração e testes do Full Throw; PHYSICS_MODEL §7).
