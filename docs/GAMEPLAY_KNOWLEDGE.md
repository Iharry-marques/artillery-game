# Conhecimento de gameplay

Consolidação do que sabemos sobre o combate clássico de referência, separado por **tipo de evidência**.
Última revisão: 06/10/2026.

## Etiquetas de evidência

| Etiqueta | Significado |
|---|---|
| **PLAYER VERIFIED** | Vem da experiência direta do desenvolvedor jogando o DDTank clássico. Evidência empírica forte, mas aproximada: é memória de régua mental, não medição em pixel. |
| **COMMUNITY RESEARCH** | Vem de guias e tabelas da comunidade ou de `research/DDTANK_DEEP_RESEARCH.md`. Hipótese até ser cruzada com outra fonte. |
| **CALIBRATED** | Valor resolvido rodando a **nossa** simulação contra uma relação conhecida, com teste automatizado. *Nenhum item ainda.* |
| **ENGINEERING INFERENCE** | Dedução matemática ou arquitetural nossa, com raciocínio documentado. Pode estar errada se as premissas estiverem. |
| **UNKNOWN** | Não sabemos. Registrado em [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md). |

---

## 1. Sistema de distância

**PLAYER VERIFIED**
- O minimapa era usado como instrumento de medição. O retângulo da câmera no minimapa representava a área visível.
- **1 largura de tela visível ≈ 10 unidades de distância horizontais.** Os jogadores dividiam mentalmente o retângulo em 10 partes.

**ENGINEERING INFERENCE**
- Conceitualmente: `distance_unit = visible_camera_world_width / 10` e
  `horizontal_distance = abs(target_x - shooter_x) / distance_unit`.
- A distância é medida **só na horizontal**. Desnível vertical é outra variável, que o jogador compensava "no olho".
- Para que a física não dependa da resolução, a unidade de distância deve ser uma **constante de mundo** e a câmera deve
  sempre mostrar exatamente 10 unidades de largura (ver DECISIONS D-002). A fórmula conceitual acima continua
  verdadeira, mas por construção da câmera, e não porque a física se ajusta à tela.

**COMMUNITY RESEARCH**
- Guias chineses: "divida o mapa em 10 partes iguais" (10等分).
- Mapas teriam de ~2,5 a ~4 larguras de tela (~25 a 40 unidades).
- Versões HTML5 widescreen teriam quebrado a régua clássica.

**UNKNOWN**
- Proporção (aspect ratio) da área de jogo clássica: 800×600 vs 1000×600 (fonte contraditória). Afeta só a altura visível, não a régua horizontal.
- Ponto de referência exato do atirador e do alvo (centro do personagem? pés? cano?).

## 2. Full Throw / High Throw (高抛)

**PLAYER VERIFIED**
- Força fixa **≈ 95**.
- Com vento 0: **Ângulo ≈ 90 − Distância**.
  - Distância 10 → ângulo 80 · Distância 5 → ângulo 85 · Distância 3 → ângulo 87.
- Reproduzir essa relação é objetivo central da simulação.

**ENGINEERING INFERENCE** (detalhes em [PHYSICS_MODEL.md](PHYSICS_MODEL.md) §4)
- Balística sem arrasto, em solo plano, gera `alcance = (v²/g)·sin(2θ)`. Com θ = 90 − D, `sin(2θ) = sin(2D)` ≈ linear
  para D pequeno. Ou seja, **a regra 90 − D surge naturalmente** de uma parábola com força fixa, desde que
  `v(95)²/g ≈ 28,6–29,0 unidades de distância`.
- O erro analítico dessa aproximação é ≤ 0,07 unidade para D = 1…10 (ajuste ótimo), mas cresce para D > 12
  (D 15 → 14,5; D 20 → 18,7). Previsão: a regra pura degrada em distâncias longas.

## 3. Vento

**PLAYER VERIFIED**
- Exibido como número decimal.
- **Constante durante o voo** do projétil.
- Para o Full Throw: **1,0 de vento ≈ 2 graus** de correção (`correção ≈ Vento × 2`).
  Exemplo: D = 10, base 80, força 95, vento contra 0,5 → correção 1° → ângulo final ≈ 79.
- **Não é uma fórmula universal.** Técnicas diferentes tinham fatores diferentes.

**COMMUNITY RESEARCH**
- Vento muda apenas entre turnos, raramente com saltos extremos.
- Valores exibidos até cerca de 5,0.
- Exemplo do high throw: D = 8, vento a favor 0,5 → 82 + 1 = 83. O sinal é coerente com o exemplo do jogador:
  vento a favor → **aumentar** ângulo; vento contra → **diminuir**.

**ENGINEERING INFERENCE**
- Se o vento é uma aceleração horizontal constante `a_w = c·W·g`, então para ângulo fixo θ a correção em graus
  por unidade de vento é **independente de força e distância**: `k(θ) = 2·sin²θ / |cos 2θ|` (com c calibrado no high throw).
  - θ ≈ 80–87 → k ≈ 2,0–2,06 (bate com o jogador)
  - θ = 30 → k = 1,0 (bate com a técnica de 30° da comunidade, que não usamos na calibração)
  - θ = 65 → k ≈ 2,56 (comunidade diz 2: **conflito**, OQ-05)
  - θ = 50 → k ≈ 6,8 (comunidade diz 2: **conflito forte**, OQ-05)
- Isso explica, pela física, **por que** cada técnica tinha seu próprio fator de vento.
- No high throw, o tempo de voo quase não varia entre 80° e 87° (sin θ ≈ 0,985–0,999). Por isso o fator ×2 é
  praticamente constante para todas as distâncias da técnica.

**UNKNOWN**
- Faixa e resolução do vento (0–5? passo de 0,1?), distribuição de geração e regra de mudança por turno.
- Se o vento tinha algum componente vertical (assumimos que não).

## 4. Força

**PLAYER VERIFIED**
- Full Throw usa força ≈ 95, o que implica uma escala de força com teto próximo de 100.

**COMMUNITY RESEARCH**
- Barra de 0 a 100, carregada segurando uma tecla, de forma linear em ~2,5–3,0 s.
- Passar do topo reiniciaria a carga (penalidade). Não verificado.
- Tabela da técnica de 30°: D 1 → 14 · D 5 → 32 · D 10 → 47,5.
- Disputa entre versões: força "universal" 95 (clássico chinês) vs 100 (versões ocidentais/2.0+).

**ENGINEERING INFERENCE**
- O **formato** da tabela de 30° (alcance ∝ força^1,9) é compatível com velocidade inicial linear na força e
  alcance ∝ v². Isso apoia `initial_speed = power × power_scale`.
- A **magnitude** da tabela de 30° não bate com a calibração do high throw: o modelo prevê 19 / 42 / 60
  onde a tabela diz 14 / 32 / 47,5 (≈ 25% a menos). Ver OQ-04.

## 5. Outras técnicas de mira

**PLAYER VERIFIED**
- Existiam técnicas e tabelas estabelecidas: Full / High Throw, Half Throw, 65°, 50°, 30°, 20°.
- Cada uma podia ter força, relação de distância e fator de vento próprios.

**COMMUNITY RESEARCH** (baixa confiança, só `DDTANK_DEEP_RESEARCH.md`)
- *Half Throw* (半抛): força ≈ 60, `Ângulo = 90 − 2·Distância ± vento`.
  - Inferência: com velocidade linear na força, a regra 90 − 2D exige força ≈ 67, e não 60. **Conflito** (OQ-06).
- *65°*: ângulo 65 ± 2·Vento; força por tabela.
- *50°*: ângulo 50 ± 2·Vento; força por tabela.
- *30°*: ângulo 30 ± Vento; força por tabela (acima).
- *20°*: sem dados.

**ENGINEERING INFERENCE**
- Técnicas são estratégias humanas de operar UMA simulação. No código, viram dados + preditores usados por
  testes, Lab e (talvez) dicas de UI. Nunca alteram a trajetória.

## 6. Física geral

**PLAYER VERIFIED**
- Trajetórias altamente previsíveis e aprendíveis.

**COMMUNITY RESEARCH**
- Integração simples (provavelmente Euler) em timestep fixo; sem arrasto; vento como aceleração horizontal constante.
- Constantes sugeridas (gravidade 450 px/s², 12,5 px/s por ponto de força, vento 20 px/s² por unidade, 30 Hz) **sem derivação**: tratar como LOW.

**ENGINEERING INFERENCE**
- O modelo determinístico candidato tem, na prática, **um único grau de liberdade não fixado pelas regras conhecidas:
  a escala de tempo** (gravidade em unidades/s²). Ver PHYSICS_MODEL §4.6.

## 7. Outros sistemas (só referência, fora do escopo atual)

**COMMUNITY RESEARCH**
- Loop de batalha síncrono: movimento → mira → força → tiro → câmera segue → impacto → dano → terreno → próximo turno.
- Ordem de turno por "atraso" (delay) acumulado, e não alternância fixa. Valores contraditórios na fonte.
- Hitbox de personagem indivisível (sem headshot); dano por decaimento radial a partir do epicentro.
- Terreno destrutível por subtração circular; pedaços soltos ficam suspensos (sem gravidade de terreno).
- Personagem sem pulo; sobe rampas até ~45°; morte ao cair abaixo do limite inferior do mapa.
- Ângulo controlado em passos de 1°; limites de ângulo dependem da arma.

**UNKNOWN**
- Fórmulas de dano, raio de explosão, tamanho de cratera, regra de atraso de turno, stamina.
