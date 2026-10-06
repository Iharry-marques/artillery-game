# Ballistics Lab

Instrumento de engenharia para **inspecionar** a simulação balística determinística (Marco 2).
Não é a cena de batalha nem UI de produção.

## Como abrir

```bash
export GODOT=~/Downloads/Godot.app/Contents/MacOS/Godot   # se o Godot não estiver no PATH nem em /Applications
tools/run_ballistics_lab.sh
```

O Lab também é a cena principal do projeto: no editor do Godot, **F5** (Run Project) o abre.

Captura automática (screenshots de todos os cenários e modos de câmera, depois fecha):

```bash
tools/run_ballistics_lab.sh --capture=/caminho/absoluto/para/pasta
```

A captura precisa de uma janela real: o modo headless não gera imagem.

## Princípio

A trajetória exibida é **exatamente** a saída de `ProjectileSimulation.simulate_to_plane()`: as amostras e os tempos de
amostra do `BallisticResult`. O Lab não faz conta de trajetória. O playback interpola entre amostras consecutivas
(distância à parábola verdadeira ≤ ~2,5e-4 u com dt = 1/60). Os helpers de mira chamam `BallisticEvidence` (técnicas
humanas) e `BallisticSolver` (problemas inversos). Nenhum deles altera a física.

## Convenções

- Tudo em **u** (1 u = 1 unidade horizontal de distância). Pixels são só apresentação (`LabView.PIXELS_PER_UNIT`).
- Atirador no ponto de referência **(0, 0)**, sem hitbox e sem offset de cano (OQ-09).
- Alvo em **(facing × distância, target y)**.
- **Target y segue a convenção do Godot: y cresce para baixo.** `+2` = 2 u **abaixo** do atirador; `−2` = 2 u **acima**.
  O painel mostra também "ABOVE/BELOW shooter".
- Vento no referencial do mundo (+ empurra para +x). O painel mostra o vento relativo (a favor / contra).
- **Impacto** = cruzamento descendente do plano horizontal na altura do alvo.
  `impact error = impact_x − target_x`; o painel também diz se o tiro foi longo ou curto na direção do tiro.

## Tela

| Área | Conteúdo |
|---|---|
| Mundo (esquerda) | Grade: linha a cada 1 u, mais forte a cada 5 u, azul a cada 10 u (uma tela de batalha); linha y = 0; rótulos x/y nas bordas. Trajetória (ciano), lançamento, ápice (lilás), plano do alvo (tracejado laranja), impacto (X vermelho), colchete de erro (amarelo), marcador de playback (branco) |
| Painel (direita, topo) | Leitura fixa: tiro, alvo, resultado (impacto, erro, tempo de voo, ápice, altura máxima, terminação, passos), modelo (K e razão do vento CALIBRATED; gravidade **PROVISIONAL**), regra do Full Throw para o D/vento atual, câmera e área visível em u |
| Painel (direita, abaixo) | Cenários, câmera, playback, parâmetros do tiro, helpers de mira |

## Câmeras

| Modo | Comportamento |
|---|---|
| **Battle (10 u)** | Largura visível = `GameMetrics.battle_view_width_units` (10 u) em qualquer resolução. Centro horizontal = ponto médio atirador–alvo; y = 0 a 70% da altura. Com D = 10, atirador e alvo ficam exatamente nas bordas: é "uma tela inteira". O Full Throw **sai pelo topo** (ápice ≈ 14 u); isso é o comportamento do modelo, não um defeito do Lab |
| **Follow** | Mesma largura de 10 u, centrada no marcador de playback (Play/Pause/Restart, velocidade ajustável). O tempo segue o tempo simulado (×1 por padrão) |
| **Fit (analysis)** | Enquadra trajetória, atirador, alvo e ápice com folga. Muda a escala; **não representa gameplay** |

## Helpers (só previsão)

- **Apply Full Throw (evidence preset):** força 95 e ângulo = 90 − D + 2 × vento relativo (E-02/E-03/E-04). Se o ângulo
  sair de 0–90°, ele **não** é cortado e o painel avisa (OQ-22).
- **Solve angle (high / low):** `BallisticSolver.solve_angle` no ramo alto [45°, 90°] ou baixo [0,5°, 45°], com distância,
  altura do alvo, força e vento atuais.
- **Solve power:** `BallisticSolver.solve_power` em [0,01, 200] com o ângulo atual. Acima de 100 avisa "above the gauge".
- Sem solução: o painel mostra **NO SOLUTION** e nada é alterado.

## Cenários de verificação manual

| ID | Cenário | Valores de referência (automação, 06/10/2026) |
|---|---|---|
| A | Full Throw clássico: D 10, 80°, força 95, sem vento | impacto 9,9299; erro −0,0701; T 4,0000 s; ápice (4,9649; −14,0788) |
| B | Full Throw médio: D 5, 85°, força 95 | impacto 5,0415; erro +0,0415; T 4,0463 s |
| C | D 10, vento contra 0,5, ângulo da regra (79°) | impacto 9,9136; erro −0,0864 |
| D | D 10, vento a favor 0,5, ângulo da regra (81°) | impacto 9,9460; erro −0,0540 |
| E | D 5, alvo 2 u **acima** (y = −2), 85° | impacto 4,8600; erro −0,1400 (curto) |
| F | D 5, alvo 2 u **abaixo** (y = +2), 85° | impacto 5,2108; erro +0,2108 (longo) |

E e F não têm regra de jogador conhecida: servem para explorar a OQ-20.
