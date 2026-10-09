# Artillery Game (nome provisório)

Jogo de artilharia 2D original, por turnos, feito em Godot 4.x / GDScript.

O combate clássico do DDTank é usado só como **referência técnica de comportamento**: queremos
reconstruir as relações matemáticas que tornavam a mira aprendível (ex.: `Ângulo = 90 − Distância`
com Força 95). Arte, personagens, mapas, armas, nomes e identidade serão próprios.

## Estado atual

Marco 4 concluído: **Battle Reference Clone**. É a batalha jogável com personagens chibi proxy (Blender procedural),
terreno texturizado, fundo em parallax, efeitos e HUD na composição clássica de artilharia, tudo sobre a mesma balística
calibrada. Veja [docs/REFERENCE_CLONE.md](docs/REFERENCE_CLONE.md),
[docs/ART_DIRECTION_PROXY.md](docs/ART_DIRECTION_PROXY.md), [docs/COMBAT_SANDBOX.md](docs/COMBAT_SANDBOX.md),
[docs/PROGRESS.md](docs/PROGRESS.md),
[docs/PHYSICS_MODEL.md](docs/PHYSICS_MODEL.md) e [docs/BALLISTICS_LAB.md](docs/BALLISTICS_LAB.md).

```bash
export GODOT=/caminho/para/Godot        # opcional se estiver no PATH ou em /Applications
tools/run_tests.sh                      # checagem estática + testes
tools/ballistics/calibrate.sh           # relatório de calibração
tools/run_combat_sandbox.sh             # JOGAR: abre o Combat Sandbox (também F5 no editor)
tools/run_ballistics_lab.sh             # abre o Ballistics Lab
tools/blender/render_reference_character.sh   # regera os sprites proxy (Blender)
```

## Estrutura

```
CLAUDE.md          instruções permanentes para o agente de engenharia
docs/              visão, conhecimento de gameplay, evidências, métricas, física, arquitetura, decisões
research/          material de pesquisa externo (hipóteses, não verdades) + avaliação de confiabilidade
godot/             projeto Godot (res://): assets, scenes, scripts, shaders, tests
blender/           arquivos-fonte .blend (vazio: a arte proxy é gerada por tools/blender/*.py)
tools/             ballistics (calibração/análise), capture (medição de vídeo), blender (bpy/pipeline)
```

Diretórios vazios não são versionados pelo git; passam a existir no repositório quando recebem conteúdo.

## Comece por

1. [docs/GAME_VISION.md](docs/GAME_VISION.md)
2. [docs/GAMEPLAY_KNOWLEDGE.md](docs/GAMEPLAY_KNOWLEDGE.md)
3. [docs/PHYSICS_MODEL.md](docs/PHYSICS_MODEL.md)
4. [docs/OPEN_QUESTIONS.md](docs/OPEN_QUESTIONS.md)
