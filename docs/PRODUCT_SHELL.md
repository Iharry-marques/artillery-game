# Product Shell (Marco 5)

O jogo deixa de ser só uma batalha e vira um **produto navegável offline**, com o fluxo clássico de jogos de
artilharia como referência funcional. Todo conteúdo (nomes, itens, inimigos, prédios, ícones) é **original**.
Não há backend, login, pagamento real nem multiplayer online: salas, jogadores, ranking, guilda e amigos são
simulados localmente.

## Como jogar

```bash
tools/run_game.sh                          # tela inicial -> personagem -> Cidade
tools/run_combat_sandbox.sh                # sandbox de batalha (hot-seat, ferramentas de debug)
tools/run_shell_capture.sh /dir/absoluto   # revisão visual: telas + PvP + PvE jogados pela IA
```

Janela padrão 1440×810, redimensionável; a UI escala a partir de 1600×900 (`canvas_items`/`expand`).
**F11** ou **Alt+Enter** alterna tela cheia. A câmera de batalha mostra sempre 10 u de largura.

## Fluxos

```
BOOT → PERSONAGEM → CIDADE ─┬─ BOLSA / STATUS / FERREIRO / LOJA / missões / correio
                            ├─ SALÃO DE JOGOS → SALA DE BATALHA → BATALHA PvP → RESULTADO → sala / cidade
                            └─ EXPEDIÇÃO → SALA DO GRUPO → BATALHA PvE (3 estágios) → RESULTADO → expedição / cidade
```

| Tela | Cena | O que faz |
|---|---|---|
| Boot | `scenes/shell/boot.tscn` | Continuar, novo personagem, tela cheia, Ballistics Lab, **resetar perfil** (confirmação dupla), sair |
| Personagem | `character_create.tscn` | Apelido e roupa (azul/vermelha) |
| Cidade | `city.tscn` | 7 prédios clicáveis (Salão, Expedição, Ferreiro, Loja, Guilda, Correio, Hall da Fama), painel do jogador, log, atalhos com badges |
| Status | `status.tscn` | Base + equipamento = total, HP, harm, armor, dano no centro, crítico |
| Bolsa | `bag.tscn` | 48 espaços, abas, detalhes com comparação, equipar/desequipar/abrir/vender, pilhas |
| Ferreiro | `blacksmith.tscn` | Fortalecer (funcional), Compor, Fundir, Transferir |
| Loja | `shop.tscn` | Armas, Roupas, Itens de batalha, Materiais; Gold / Coupons / Vouchers locais |
| Salão de Jogos | `game_hall.tscn` | Lista de salas (nº, nome, modo, mapa, jogadores, estado, cadeado), criar, entrar, entrada rápida |
| Sala de Batalha | `battle_room.tscn` | Times azul/vermelho, host, pronto, trocar mapa/time, adicionar IA; host IA inicia 2 s após o "pronto" |
| Batalha | `scenes/gameplay/combat_sandbox.tscn` | Mesma cena do sandbox, em modo batalha quando há `GameSession.pending_battle` |
| Resultado | `result.tscn` | Vitória/derrota, estatísticas, EXP/Gold, level up, **virar 1 de 4 cartas** |
| Expedição | `expedition.tscn` | Masmorra, estágios com inimigos, dificuldade Normal/Difícil/Herói |
| Sala do Grupo | `party_room.tscn` | Você + aliado IA opcional, iniciar |

Missões, correio, amigos, ranking, guilda e configurações são janelas modais da Cidade (amigos/ranking/guilda são mock).

## Arquitetura

- `scripts/meta/`: domínio puro, testável headless (perfil, inventário, equipamento, carteira, progressão, missões,
  ferreiro, loja, salas, recompensas, save, catálogo de conteúdo). `GameSession` é o singleton estático
  (`get_instance()` / `replace_instance()` para testes).
- `scripts/shell/`: apresentação (UiKit, ShellScreen, ScreenRouter, widgets, uma tela por script).
- `scripts/game/combat/`: regras de batalha. `BattleSetup` (PvP/PvE) → `CombatMatch`; `CombatLoadout` leva atributos;
  `DamageFormula` calcula dano; IA em `ArtilleryPlanner` + `AiTurnDriver` usando **as mesmas requisições do humano**.
- A balística calibrada não mudou: a IA mira com `BallisticSolver` e erro gaussiano; a trajetória é a de sempre.

## Batalha em modo produto

- PvP: duelo 1v1 ou 2v2, turnos intercalados entre times, oponentes IA (erro de mira 1,8°).
- PvE: 3 estágios (Caminho Musgoso, Cume das Pedras, Covil do Rei Concha). HP do grupo **passa de um estágio para
  o outro**; kits de cura são um estoque único da expedição. Inimigos: corpo-a-corpo (anda e golpeia), artilheiro
  (arremessa pedras) e chefe (alvo grande, fixo, onda de choque a cada 3ª ação).
- Teclas: A/D mover · W/S ângulo · ESPAÇO força · **1** kit de cura · F2 hitbox · F3 debug · **ESC/Leave** duas vezes
  para desistir (conta como derrota, sem recompensa).
- O sandbox puro (sem batalha pendente) continua com R/Z/F e a captura `--capture` dos marcos anteriores.

## Fórmulas (REFERENCE ESTIMATE)

Todas são estimativas de engenharia para um loop local satisfatório; nenhuma é dado confirmado do jogo clássico.

| Sistema | Fórmula | Código |
|---|---|---|
| Atributos base | 10 + 3 × (nível − 1) em ataque, defesa, agilidade e sorte | `character_stats.gd` |
| HP máximo | 950 + 50 × nível + defesa / 8 + bônus de HP | `character_stats.gd` |
| Combat Power | atk + def + agi + sorte + 2 × harm + 3 × armor + HP / 10 (cosmético) | `character_stats.gd` |
| Dano | harm × (1 + atk/1000) × (1 − def/(def+1000)) × (1 − min(armor × 0,0005; 0,6)) × queda | `damage_formula.gd` |
| Crítico | chance = sorte / 4000, ×1,5 | `damage_formula.gd` |
| EXP por nível | 100 + 60n + 20n², nível máximo 40 | `progression.gd` |
| Fortalecer | chance = Σ força das pedras (0,30/0,55/0,85/1,20) × fator do nível (1 … 0,02) + amuleto 15%; máx. +12, até 3 pedras | `enhancement_rules.gd` |
| Custo / falha | 150 × N² + 100 Gold; abaixo de +3 nunca perde nível; Selo Guardião protege | `enhancement_rules.gd` |
| Bônus do fortalecimento | arma: +3 ataque e +9% harm por nível; roupa/chapéu: +3 defesa e +12% armor por nível | `enhancement_rules.gd` |
| Compor | +3 no atributo da pedra elemental, teto 30, 100 Gold | `blacksmith.gd` |
| Fundir | 4 pedras nível N → 1 nível N+1, 85%, 300 × N Gold | `blacksmith.gd` |
| Transferir | move nível e composição entre itens do mesmo tipo, 2000 Gold | `blacksmith.gd` |
| Recompensa PvP | vitória: 120 + 15 × nível EXP, 300 + 30 × nível Gold; derrota: 50 + 5 × nível EXP, 120 Gold | `reward_calculator.gd` |
| Recompensa PvE | EXP/Gold dos inimigos abatidos + bônus de conclusão, × 1 / 1,7 / 2,6 pela dificuldade | `reward_calculator.gd` |
| Dificuldade PvE | HP inimigo × 1 / 1,5 / 2,2; dano × 1 / 1,3 / 1,7 | `pve_instance_definition.gd` |
| Cartas | vitória → 4 cartas sorteadas do pool (PvP) ou do loot da masmorra; o jogador vira uma | `reward_calculator.gd` |

## Save local

- Arquivo: `user://reference_clone_save.json` (no macOS, `~/Library/Application Support/Godot/app_userdata/<projeto>/`).
- Guarda perfil, nível, EXP, carteira, inventário, equipamento, fortalecimento/composição, missões, correio,
  contadores e o estado do RNG do perfil. Salvo automaticamente após cada ação que altera o perfil.
- Reset: tela inicial → "Reset profile" (pede confirmação). Testes e capturas usam arquivos próprios.

## Revisão visual

`tools/run_shell_capture.sh <dir>` usa um save descartável, percorre as telas, joga um duelo PvP e uma expedição PvE
com a IA nos dois lados e salva as imagens (cidade, status, bolsa, loja, ferreiro, salão, sala, batalha PvP,
resultado PvP, seleção PvE, sala do grupo, estágio 1, chefe, resultado PvE, cidade depois).
