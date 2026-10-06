# Progresso

Diário de engenharia. Entrada mais recente no topo.

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
- Nada foi comitado.

**Próximo**
- Marco 1: núcleo balístico headless (instalar Godot, `project.godot`, GameMetrics, ProjectileSimulation pura, solver de calibração e testes do Full Throw; PHYSICS_MODEL §7).
