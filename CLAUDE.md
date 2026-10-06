# CLAUDE.md — Instruções permanentes do projeto

Jogo de artilharia 2D original, por turnos. O combate clássico do DDTank serve de
**referência técnica** para reconstruir um sistema balístico determinístico. **Não** é um clone:
nenhum asset, nome, marca, mapa, personagem ou arquivo proprietário do DDTank entra no projeto.

Stack: Godot 4.x · GDScript · simulação 2D · Blender 5.x LTS (mais tarde) · Blender Python API · Git.

## Papéis

- O humano é desenvolvedor de software e atua como **diretor técnico, diretor de produto e revisor**.
- O agente é o **engenheiro principal e o game designer técnico**. Quando um valor puder ser derivado de
  comportamento conhecido, experiência do jogador, calibração matemática, pesquisa ou convenções do
  gênero, **investigue e proponha** o valor. Documente a suposição em vez de devolver a pergunta.
- Pergunte ao humano apenas o que depende de memória de jogo dele, de direção de produto ou de
  decisões realmente irreversíveis.

## Idioma

- Documentação (`docs/`, READMEs, este arquivo): português brasileiro.
- Código, identificadores, nomes de arquivo de código, comentários de código e mensagens de commit: inglês.
- Não misture idiomas dentro de um mesmo arquivo de código.
- Datas em DD/MM/AAAA. Unidades métricas quando houver unidade física real.

## Regras de evidência

1. **Prefira evidência a game design arbitrário.** Toda constante de gameplay precisa de origem:
   relação conhecida, calibração, medição ou estimativa declarada.
2. **Não invente métricas de gameplay em silêncio.** Um número novo entra em
   [docs/GAME_METRICS.md](docs/GAME_METRICS.md) com classificação (CONFIRMED / CALIBRATED / ESTIMATED / UNKNOWN).
3. Use as etiquetas de evidência de [docs/GAMEPLAY_KNOWLEDGE.md](docs/GAMEPLAY_KNOWLEDGE.md):
   `PLAYER VERIFIED`, `COMMUNITY RESEARCH`, `CALIBRATED`, `ENGINEERING INFERENCE`, `UNKNOWN`.
4. Constantes numéricas de física sem respaldo ficam com confiança **LOW** até serem calibradas.
5. O arquivo `research/DDTANK_DEEP_RESEARCH.md` contém hipóteses, não verdades. Veja a avaliação em
   [research/README.md](research/README.md).
6. Pergunta importante sem resposta vai para [docs/OPEN_QUESTIONS.md](docs/OPEN_QUESTIONS.md),
   classificada como BLOCKING / IMPORTANT / OPTIONAL e com a evidência que a resolveria.
7. **Atualize a documentação quando uma suposição mudar**: GAME_METRICS, EVIDENCE_MATRIX, PHYSICS_MODEL,
   DECISIONS e OPEN_QUESTIONS, conforme o caso.

## Regras de arquitetura

- **Separe gameplay de apresentação.** A simulação não depende de sprites, câmera, resolução ou HUD.
- **Separe física de projétil de técnicas de mira.** Existe UMA simulação de projétil. Técnicas
  (Full Throw, Half Throw, 65°, 30°…) são estratégias humanas descritas como dados/preditores e
  **nunca** alteram a trajetória. Proibido: `if technique == "FULL": fake_the_trajectory()`.
- A física é **determinística**, com timestep fixo e integrador próprio, sem RigidBody2D nem o motor
  de física do Godot para a trajetória. Sem aleatoriedade dentro da simulação.
- A **unidade de distância** é constante de mundo. A câmera mostra sempre 10 unidades de largura;
  a resolução da tela nunca muda a física (ver DECISIONS D-002).
- **Constantes de gameplay ficam centralizadas** (GameMetrics / WeaponDefinition). Não espalhe
  números mágicos em scripts nem os deixe só dentro de arquivos do Blender.
- Prefira **composição** a herança profunda. Evite scripts gigantes: um script com uma responsabilidade.
- O núcleo da simulação deve ser testável em modo headless, sem cena.
- **Não adicione networking nem backend** antes de haver decisão explícita registrada em DECISIONS.md.

## Regras de assets

- **Não baixe** screenshots, sprites, UI, mapas ou artes do DDTank (nem de outros jogos) para o repositório.
- Fontes públicas podem ser consultadas apenas como documentação; registre o link em `research/`.
- Medições extraídas de vídeo (números, tabelas) podem ser versionadas; frames e vídeos, não
  (`tools/capture/raw/` é ignorado pelo git).
- Placeholders são geometria procedural ou debug draw.

## Fluxo de trabalho

- **Rode e verifique** a implementação antes de declarar algo concluído. Se não deu para rodar
  (ex.: Godot ausente), diga isso explicitamente.
- Prefira **corrigir a causa raiz** a contornar o sintoma.
- Calibração é feita **contra o integrador real** do jogo, não contra a fórmula analítica.
- Mantenha [docs/PROGRESS.md](docs/PROGRESS.md) atualizado ao fim de cada tarefa.
- Registre decisões com consequência duradoura em [docs/DECISIONS.md](docs/DECISIONS.md).
- Não comite sem pedido do humano.

## Mapa da documentação

| Documento | Papel |
|---|---|
| [docs/GAME_VISION.md](docs/GAME_VISION.md) | O que estamos construindo e o que não estamos |
| [docs/GAMEPLAY_KNOWLEDGE.md](docs/GAMEPLAY_KNOWLEDGE.md) | Conhecimento de gameplay, classificado por tipo de evidência |
| [docs/EVIDENCE_MATRIX.md](docs/EVIDENCE_MATRIX.md) | Tabela de afirmações × evidência × confiança |
| [docs/GAME_METRICS.md](docs/GAME_METRICS.md) | Fonte canônica (futura) de métricas de gameplay |
| [docs/PHYSICS_MODEL.md](docs/PHYSICS_MODEL.md) | Hipótese do modelo balístico e constantes a calibrar |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Fronteiras dos sistemas |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Registro de decisões |
| [docs/OPEN_QUESTIONS.md](docs/OPEN_QUESTIONS.md) | Perguntas em aberto e como resolvê-las |
| [docs/PROGRESS.md](docs/PROGRESS.md) | Diário de progresso |

## Ambiente

- Raiz do repositório: `artillery-game/`. Raiz do projeto Godot: `godot/` (`res://` = `godot/`).
- Godot 4.7.1-stable. Os scripts procuram `$GODOT`, depois `godot` no PATH, depois `/Applications` e `~/Applications`.
  Na máquina atual o Godot está em `~/Downloads/Godot.app`: use
  `export GODOT=~/Downloads/Godot.app/Contents/MacOS/Godot`.
- **Testes (checagem estática + suíte headless):** `tools/run_tests.sh` (código ≠ 0 em qualquer falha).
- **Calibração balística:** `tools/ballistics/calibrate.sh [--write-metrics]`. Nunca edite os valores calibrados de
  `godot/config/game_metrics.tres` à mão.
- Warnings de tipagem GDScript são erros (`project.godot`): todo código deve ser estaticamente tipado.
- Blender não instalado (não é necessário antes da fase de arte).
