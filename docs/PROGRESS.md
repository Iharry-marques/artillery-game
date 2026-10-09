# Progresso

Diário de engenharia. Entrada mais recente no topo.

---

## 09/10/2026 · Marco 4: Battle Reference Clone

**Feito**
- Pipeline Blender procedural (`tools/blender/create_reference_character.py` + `render_reference_character.sh`): chibi
  original com cel shading e contorno, variantes azul/vermelha, idle/mira, arma e projétil, `proxy_meta.json`.
- Personagem no Godot como CharacterRoot (Visual/Body, WeaponPivot/Weapon girando no ângulo real, Head/HeadHitbox).
  Hitbox subiu para 0,72 u, alinhada à arte (testado). Lançamento na ponta do cano; saída da própria cabeça tratada.
- `ReferenceBattleMap`, shader de terreno (grama, terra, contorno, chamuscado), fundo em parallax manual, efeitos
  (rastro, explosão, detritos, dano, flash, tremor), HUD na composição clássica, minimapa refeito, overlay F2.
- Testes: 73 (62 anteriores + 11 novos: arte/escala/alinhamento, mira, minimapa, cena).
- Revisão visual por `--capture` em janela real, com 7 problemas corrigidos (ver REFERENCE_CLONE.md). Calibração e
  `game_metrics.tres` idênticos; Lab ok.

**Não feito (de propósito)**
- Arte final, multiplayer, itens, lojas, mascotes, atributos de RPG, ordem de turno por atraso.

---

## 06/10/2026 · Marco 3: Combat Sandbox jogável

**Revisão inicial:** árvore limpa, 34/34 testes, calibração reproduzível.

**Feito**
- `scenes/gameplay/combat_sandbox.tscn` (cena principal): mover, mirar, carregar, atirar, câmera seguindo o projétil,
  cratera, dano, queda, turno alternado, fim de partida e reset (R). `tools/run_combat_sandbox.sh` (+ `--capture`).
- Núcleo: `BallisticCollisionQuery`, `BallisticHit`, `simulate_with_collisions` (mesma trajetória, término por colisão),
  `TerrainMask`.
- Lógica pura em `scripts/game/combat/` e nós em `scripts/game/sandbox/`; auxiliares de apresentação movidos para
  `scripts/presentation/` (Lab atualizado).
- Placeholders centralizados em `combat_rules.tres`; `docs/COMBAT_SANDBOX.md`.
- Testes: 62 (34 anteriores + 28 novos: terreno, colisão, dano, turnos, queda, vento, reset).
- Bugs encontrados e corrigidos: geometria da cabeça em float32 (5e-8 u de erro, agora escalares de 64 bits); a partida
  não terminava se o jogador inativo morresse fora do turno; o reset não limpava o toggle de vento 0.
- Verificação jogável por captura automática numa janela real (Full Throw carregado na barra, voo, impacto, resposta
  do P2, cratera e queda, partida até HP 0, overlay, reset). Calibração byte a byte idêntica; Lab ok.

**Não feito (de propósito)**
- Blender, arte final, itens, atributos de RPG, ordem de turno por delay, rede, backend.

---

## 06/10/2026 · Marco 2: Ballistics Lab visual

**Revisão inicial**
- 20/20 testes e calibração ok antes de mudar algo. O repositório **não** estava limpo: `project.godot` tinha o cabeçalho
  reescrito pelo Godot (adotado), e o relatório mudava a cada execução por causa do tempo de execução (corrigido no gerador, D-023).
- Terminologia: K é comprimento (u), não "adimensional". Corrigido em PHYSICS_MODEL, GAME_METRICS, DECISIONS, comentários
  e no gerador do relatório. Valores inalterados.

**Feito**
- `scenes/debug/ballistics_lab.tscn` + `scripts/debug/ballistics_lab/` (14 scripts focados). Trajetória só de `ProjectileSimulation`.
- Núcleo: `BallisticResult.sample_times`; `BallisticSolver` com `target_y` e tratamento da borda inalcançável do intervalo;
  `GameMetrics.battle_view_width_units = 10`.
- Grade 1/5/10 u, alvo com altura (y para baixo), Full Throw preset sem clamp (OQ-22 visível), solver de ângulo/força com
  NO SOLUTION, painel de leitura, câmeras Battle/Follow/Fit, playback em tempo simulado.
- `tools/run_ballistics_lab.sh` (+ `--capture`), `docs/BALLISTICS_LAB.md`.
- Testes: 34 (20 anteriores + 14 novos). Calibração reproduz o Marco 1 byte a byte.
- Revisão visual feita pelo agente via screenshots: corrigidos leitura fora da dobra do painel, rótulos cortados nas bordas
  e falta de folga no Fit View.

**Não feito (de propósito)**
- Cena de batalha, terreno, personagens, HUD de batalha, turnos, dano, Blender, barra de carga de força.

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
