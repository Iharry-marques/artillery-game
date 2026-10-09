# Perguntas em aberto

**Importância:**
- **BLOCKING:** impede o próximo marco.
- **IMPORTANT:** afeta a fidelidade do gameplay; precisa ser resolvida antes da fatia vertical.
- **OPTIONAL:** refinamento.

**Tipos de evidência que resolvem:** memória do jogador · medição em vídeo de gameplay · tabela da comunidade ·
experimento matemático (na nossa simulação) · pesquisa externa mais profunda · decisão de design (quando a
fidelidade histórica não importa).

Toda pergunta tem um **default proposto** para não travar o trabalho. O default é usado até a evidência chegar.

Última revisão: 06/10/2026 (Marco 1).

---

## BLOCKING

Nenhuma no momento. As duas que existiam foram reclassificadas no Marco 1:
- OQ-09 → IMPORTANT. A calibração usa uma geometria sem personagem (D-013).
- OQ-18 → RESOLVIDA (D-016).

## IMPORTANT

### OQ-09 · Ponto de lançamento e ponto de referência do alvo
- **Pergunta:** de onde sai o projétil (pés, centro, cano?) e qual ponto do alvo define "distância" e "acerto"?
  Em D = 3, um offset de cano de 0,3 u já muda o resultado.
- **Status:** **não bloqueia o núcleo balístico** (D-013: calibração com lançamento em (0, 0) e impacto no cruzamento de y = 0).
  Precisa ser resolvida antes da implementação visual/de gameplay (personagem, terreno, Lab com alvos reais).
- **Default proposto:** lançamento e medição de distância a partir do mesmo ponto de referência do personagem, com offset de
  cano zero. O Ballistics Lab (Marco 2) usa exatamente isso: atirador em (0, 0), sem hitbox e sem cano.
- **Marco 4:** o lançamento passou para a ponta do cano (pivô 0,16/0,27 u + 0,45 u na direção da mira). A 80°, o tiro sai
  ~0,24 u à frente e ~0,71 u acima dos pés. Do spawn, o Full Throw carregado na barra (95,3) acertou a cabeça; o contato foi em x = 23,21, com a cabeça centrada em 23,00.
- **Combat Sandbox (Marco 3):** usa cano provisório de 0,30 u à frente e 0,40 u acima dos pés e mede D pé a pé. Efeito
  observado: o Full Throw cai ~0,3 u além do previsto pela calibração. Do spawn (D = 10, força exata 95) ainda acerta a
  cabeça, mas com D = 8,93 e o alvo 0,4 u mais baixo passou 0,34 u da cabeça (só splash). Se no jogo original a regra
  acertava "no centro", o lançamento provavelmente ficava mais perto da referência de medição.
- **Resolve com:** medição em vídeo (de onde o projétil aparece) + decisão de design.

### OQ-01 · Tempo de voo do Full Throw
- **Pergunta:** quantos segundos durava um Full Throw a ~10 de distância? Define a gravidade (o *feel*).
- **Default:** 4 s (D-010) → g = 7,039 u/s². Trocar não altera os pontos de impacto (verificado em teste).
- **Resolve com:** memória do jogador (ordem de grandeza) ou cronometragem em vídeo.

### OQ-02 · Altura do ápice do Full Throw
- **Pergunta:** o projétil do Full Throw subia ≈ 14 u (≈ 1,4 largura de tela) acima do atirador, como o modelo prevê?
  Simulador: 14,08 u em D = 10, independente da gravidade.
- **Resolve com:** vídeo (tempo fora da tela no topo + câmera seguindo) ou memória ("sumia da tela por quanto tempo?").
  Se o ápice real for muito diferente, o modelo sem arrasto está errado.

### OQ-04 · Magnitude da tabela de força de 30°
- **Pergunta:** a tabela D1 → 14, D5 → 32, D10 → 47,5 é real?
- **Medido no Marco 1:** o modelo calibrado no Full Throw pede 18,95 / 42,36 / 59,91 (razão 1,35 / 1,32 / 1,26).
  Como a razão não é constante, não basta mudar a escala de força. O fator de vento de 30° (×1), porém, o modelo
  reproduz (×1,00).
- **Resolve com:** memória do jogador (lembra alguma força de técnica de ângulo baixo?) ou tabela da comunidade com fonte verificável.
- **Default:** confiar no Full Throw; tratar a tabela como LOW.

### OQ-05 · Fator de vento das técnicas de 65° e 50°
- **Pergunta:** a comunidade diz ×2 para ambas.
- **Medido no Marco 1:** 65° → ×2,52 (2,55 contra / 2,49 a favor). 50° → com vento contra **não há** ângulo que compense
  com a mesma força; a favor, +5,1°. A compensação por força a 50° seria de ±0,4 a ±1,2 ponto por 1,0 de vento (D = 1…10).
- **Resolve com:** memória do jogador / tabela da comunidade; experimento na simulação após o marco 1.
  Hipótese: a técnica de 50° compensava o vento pela **força**, não pelo ângulo.

### OQ-06 · Half Throw
- **Pergunta:** força e regra exatas. Fonte: força ≈ 60 e 90 − 2D.
- **Medido no Marco 1:** melhor força para 90 − 2D = 68,5 (exata por distância: 66,8 a 69,5). Com força 60 o tiro cai
  19–26% curto, e a regra coerente seria ≈ 2,5–3,0° por unidade. Coincidência a investigar: o modelo pede força 59,9
  para 30° em D = 10.
- **Resolve com:** memória do jogador; tabela da comunidade.

### OQ-07 · Full Throw além de 10 unidades
- **Pergunta:** a regra 90 − D funcionava em D = 15, 20? O modelo calibrado (K = 29,03) prevê que o tiro cai curto
  (≈ 14,5 / 18,7). Dentro de D = 1…10 o erro máximo é 0,07 u.
  Jogadores usavam correções para distâncias longas?
- **Resolve com:** memória do jogador; vídeo.

### OQ-08 · Vento: faixa, passo e geração
- **Pergunta:** faixa (0–5?), passo (0,1?), como muda entre turnos, se há turnos sem vento.
- **Default:** −5,0 a +5,0, passo 0,1, passeio aleatório com seed determinística.
- **Resolve com:** memória do jogador; vídeo.

### OQ-10 · Barra de força
- **Sandbox (Marco 3):** 0 → 100 em 2,5 s, linear, trava em 100. A 60 fps cada frame soma ~0,67 de força, e a 10 u de
  distância isso desloca o impacto ~0,14 u. Na captura automática a carga real parou em 95,68.
- **Pergunta:** tempo de carga 0 → 100, comportamento ao passar de 100 (trava? volta a 0? oscila?).
- **Default:** linear, 0 → 100 em 2,5 s; ao estourar, volta a 0 (fonte COMMUNITY).
- **Resolve com:** memória do jogador; vídeo.

### OQ-11 · Limites de ângulo por arma
- **Pergunta:** quais faixas existiam? A fonte cita 20–65 / 55–75 / 10–40, mas o Full Throw exige até ~87.
  **Contradição:** se a arma canônica ia só até 65°, como funcionava o Full Throw a 80–87°?
  Hipóteses: limites da fonte errados; limites de outra versão; o Full Throw era feito com outra arma.
- **Default:** arma de teste com 0–90°.
- **Resolve com:** memória do jogador.

### OQ-23 · Proporções do personagem e da cabeça
- **Pergunta:** o personagem proxy (1,08 u, cabeça de 0,52 u, ~19% da altura da tela em 16:9) está na escala do jogo
  clássico? A hitbox de raio 0,25 u parece justa?
- **Evidência:** jogar o Reference Clone (F2 mostra hitbox × arte), memória do jogador, medição em vídeo (proporção
  personagem/largura de tela).
- **Status:** escolha REFERENCE PROXY / ESTIMATED, confiança LOW-MEDIUM; a pesquisa visual pública não trouxe referências utilizáveis.

### OQ-12 · Hitbox do personagem
- **Pergunta:** largura e altura em u. A fonte estima ~0,45 × 0,75 u (LOW).
- **Sandbox (Marco 3):** só a cabeça é atingível, um círculo de raio 0,25 u com centro 0,65 u acima dos pés; o corpo
  0,36 × 0,42 u é visual. ESTIMATED, a avaliar jogando.
- **Marco 4:** centro subiu para 0,72 u, para casar com a cabeça da arte proxy (0,26 × 0,24 u). Ver OQ-23.
- **Resolve com:** medição em vídeo relativa à largura da tela.

### OQ-13 · Explosão, cratera e dano
- **Pergunta:** raio de dano, raio de cratera, curva de decaimento, dano base.
- **Sandbox (Marco 3):** placeholder com dano 35, raio de dano 1,0 u (queda linear até a borda da cabeça) e cratera
  0,6 u. Uma cratera centrada na cabeça não alcança o chão. **Não** é a fórmula histórica.
- **Resolve com:** vídeo + decisão de design (fidelidade baixa aceitável).

### OQ-14 · Ordem de turno
- **Pergunta:** alternância simples ou fila por atraso (delay)? A fonte se contradiz nos números.
- **Default para a fatia vertical:** alternância simples entre 2 jogadores; delay fica para depois.
- **Resolve com:** memória do jogador + decisão de produto.

### OQ-15 · Representação do terreno
- **Resolvida no Marco 3:** máscara de ocupação em grade (D-025).

### OQ-22 · Ângulo acima de 90°
- **Pergunta:** o jogo permitia mirar acima de 90° (ligeiramente para trás)? A regra `90 − D + 2·W` exige 91° em D = 1 com
  vento a favor 1,0, em D = 2 com 1,5 e em D = 3 com 2,0. O simulador acerta esses tiros acima de 90°, mas se o jogo
  travava em 90° o jogador precisaria de outra estratégia (virar de costas? reduzir força?).
- **Default:** a física aceita qualquer ângulo; limites são regra da arma (WeaponDefinition, futuro).
- **Resolve com:** memória do jogador.

### OQ-20 · Compensação de desnível vertical
- **Pergunta:** como os jogadores corrigiam o desnível no Full Throw (regra de bolso, tipo "+1 de distância por X de altura")?
- **Ferramenta:** Ballistics Lab, cenários E (alvo 2 u acima) e F (2 u abaixo), e o campo "Target y".
- **Previsão do modelo (não é evidência):** no Full Throw o projétil desce quase na vertical, então o desnível pesa pouco.
  Em D = 5 a 85°, 2 u acima → impacto 4,86 (−0,14 u); 2 u abaixo → 5,21 (+0,21 u). Isso daria uma correção de
  ~0,07–0,1° por unidade de altura. Se o jogador lembra de corrigir bem mais que isso, o modelo está incompleto.
- **Resolve com:** memória do jogador; depois, previsão pela nossa simulação para comparar.

### OQ-24 · Fórmulas de atributos, dano e fortalecimento
- **Pergunta:** quão perto as fórmulas de RPG (HP, dano, crítico, curva de fortalecimento, EXP) devem ficar do jogo clássico?
- **Estado:** REFERENCE ESTIMATE (D-045, [PRODUCT_SHELL.md](PRODUCT_SHELL.md)); confiança LOW.
- **Resolve com:** memória do jogador (quantos acertos para derrubar alguém do mesmo nível, sensação do +5/+9) e playtest.

### OQ-25 · Ritmo das partidas PvP
- **Pergunta:** um duelo IA × IA leva ~20–35 turnos (dano ~185 por acerto, HP ~1000, acerto da IA ~35%). O clássico era mais curto?
- **Resolve com:** memória do jogador + playtest; ajuste em dano base, HP ou erro de mira da IA (sem tocar na balística).

### OQ-26 · Ordem de turno com delay e agilidade
- **Pergunta:** a agilidade deve alimentar uma fila de turnos por atraso (delay) em vez da alternância entre times?
- **Default:** alternância intercalada entre times (D-043); agilidade só entra no Combat Power. Relacionada a OQ-14.

## OPTIONAL

### OQ-03 · Aspect ratio da área de jogo clássica
- **Pergunta:** 800×600 (4:3) ou 1000×600 (5:3)? Afeta só a altura visível (7,5 u vs 6 u).
- **Default:** decidir pela apresentação; 16:9 (5,625 u de altura) é aceitável.
- **Resolve com:** pesquisa externa.

### OQ-16 · Movimento
- **Sandbox (Marco 3):** 1,6 u/s, 4 u por turno, rampa máx. 50°, sem pulo. O morro central (~53°) bloqueia a passagem,
  e paredes de cratera podem prender um personagem. Avaliar jogando.
- **Pergunta:** velocidade, stamina por turno, inclinação máxima (~45° segundo a fonte), ausência de pulo.
- **Resolve com:** vídeo + decisão de design.

### OQ-17 · Mapa
- **Pergunta:** largura (25–40 u segundo a fonte), altura, limite de morte por queda.
- **Resolve com:** decisão de design.

### OQ-19 · Git LFS para arquivos binários
- **Pergunta:** usar Git LFS para `.blend` e renders?
- **Resolve com:** decisão técnica antes do primeiro asset binário.

### OQ-21 · Técnica de 20°
- **Pergunta:** força/regra. Sem dados. O modelo prevê fator de vento ≈ 0,31.
- **Resolve com:** memória do jogador; tabela da comunidade.

## RESOLVIDAS

### OQ-18 · Infraestrutura de teste headless · resolvida em 06/10/2026
- Runner próprio sem dependência externa + checagem estática com warnings de tipagem como erro (D-016).
  Godot 4.7.1-stable. Comando: `tools/run_tests.sh`.
