# blender/

Arquivos-fonte `.blend` dos assets originais (characters, weapons, environments). Só entram na fase de arte.

Regras:

- Dimensões de gameplay (altura do personagem, hitbox, raio de cratera, escala do mundo) **não** são
  definidas aqui. A fonte é [../docs/GAME_METRICS.md](../docs/GAME_METRICS.md) e a configuração do jogo;
  o Blender consome esses valores.
- Scripts `bpy` ficam em `../tools/blender/` (DECISIONS D-007).
- Arquivos `.blend` grandes: decidir Git LFS antes do primeiro commit binário (OPEN_QUESTIONS OQ-19).
