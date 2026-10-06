# Métricas de gameplay

**Fonte canônica de toda métrica de gameplay.** Código, Blender e HUD leem os valores da configuração centralizada
(`godot/config/game_metrics.tres` via `GameMetrics`, e futuramente `WeaponDefinition`), e não reinventam números.

Regras:
- Nenhum valor sobe de categoria sem evidência registrada em [EVIDENCE_MATRIX.md](EVIDENCE_MATRIX.md).
- **CALIBRATED** exige teste automatizado contra a simulação real (`tools/run_tests.sh`).
- Valores ESTIMATED são provisórios e podem ser trocados sem cerimônia.
- Valores calibrados são regravados pela ferramenta (`tools/ballistics/calibrate.sh --write-metrics`), nunca à mão.
  Um teste falha se o `.tres` divergir de uma calibração nova.

Unidade base: **u** = 1 unidade de distância horizontal = 1,0 unidade de mundo (1/10 da largura visível da câmera).
Tempo em segundos. Ângulos em graus a partir da horizontal, na direção em que o personagem está virado.

Última revisão: 06/10/2026 (Marco 1).

---

## CONFIRMED

Relações de gameplay que o sistema **deve** reproduzir (requisitos, não constantes de implementação).

| Métrica | Valor | Fonte |
|---|---|---|
| Largura visível da câmera | 10 u | E-01 |
| Força do Full Throw | ≈ 95 | E-02 |
| Relação Full Throw, vento 0, desnível 0 | Ângulo ≈ 90 − D | E-03 |
| Correção de vento do Full Throw | ≈ 2° por 1,0 de vento (contra → −, a favor → +) | E-04 |
| Vento durante o voo | constante | E-06 |
| Determinismo | mesmo input → mesma trajetória, bit a bit, na mesma plataforma | E-09 |

## CALIBRATED

### Relações adimensionais calibradas

Valores resolvidos pelo simulador real e protegidos por teste. Não dependem da escala de tempo.

| Métrica | Valor | Como foi obtida | Resultado verificado |
|---|---|---|---|
| `ballistic_k` = v(95)² / g | **29,033036 u** | Mínimos quadrados do Full Throw, D = 1…10 | Erro médio 0,0316 u, máx. 0,0701 u. Bate com a forma fechada (Δ 2e-10) |
| `ballistic_k_reference_power` | 95 | Definição de K (força do Full Throw, E-02) | — |
| `wind_accel_ratio` = aceleração do vento por 1,0 ÷ g | **0,034401** (= g / 29,07) | Mínimos quadrados da regra ×2, D = 3…10, W = ±1 | Correção 1,976°–2,035°, erro máx. 0,035° |

### Comportamentos verificados

| Propriedade | Resultado |
|---|---|
| Invariância de timestep (dt = 1/30, 1/60, 1/120) | Diferença de impacto ≤ 1,5e-13 u |
| Impactos independentes da gravidade com K fixo | Verificado para g = 1; 3; 7,04; 12,5 |
| Simulação igual à parábola fechada (com vento) | Impacto, tempo de voo e ápice dentro de 1e-9 |

## ESTIMATED

### Valores provisórios de escala de tempo

Mudam a **duração** do voo, não onde o tiro cai. Nenhum tem evidência de gameplay.

| Métrica | Valor | Base | Confiança |
|---|---|---|---|
| Tempo de voo do Full Throw em D = 10 | 4,0 s | Escolha de engenharia (D-010) | LOW |
| `gravity` | 7,039396 u/s² | Derivada do tempo de voo de 4 s e de K | LOW |
| `power_scale` (derivado) | 0,150484 u/s por ponto | √(K·g)/95 | LOW (herda de g) |
| v(95) (derivado) | 14,296 u/s | power_scale × 95 | LOW (herda de g) |
| Aceleração do vento por 1,0 (derivada) | 0,242162 u/s² | ratio × g | LOW (herda de g) |

### Outras estimativas

| Métrica | Valor provisório | Base | Confiança |
|---|---|---|---|
| Ápice do Full Throw (D = 10) | 14,08 u acima do lançamento | Consequência de K (independe de g) | MEDIUM (testável em vídeo) |
| `time_step` | 1/60 s | Engenharia; não afeta impactos | — |
| `max_flight_time` | 30 s | Limite de segurança | — |
| Escala de apresentação | 1 u = 100 px de mundo | Conveniência. Não afeta física | LOW |
| Velocidade de carga da força | 0 → 100 em ~2,5–3,0 s | COMMUNITY RESEARCH | LOW |
| Largura de mapa | ~25–40 u | COMMUNITY RESEARCH | LOW |
| Altura do personagem | ~12–15% da altura visível | COMMUNITY RESEARCH; depende do aspect ratio | LOW |

### Previsões do modelo (não são métricas de jogo)

| Técnica | Previsão | Comunidade |
|---|---|---|
| 30°: fator de vento | ×1,00 (média de 1,09 contra / 0,91 a favor) | ×1 |
| 65°: fator de vento | ×2,52 | ×2 |
| 50°: fator de vento | sem solução por ângulo com vento contra | ×2 |
| 20°: fator de vento | ×0,30 | — |
| Half Throw (90 − 2D): força | 68,5 (melhor ajuste) | ≈ 60 |
| 30°: força D = 1 / 5 / 10 | 18,95 / 42,36 / 59,91 | 14 / 32 / 47,5 |

## UNKNOWN

Ver [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md) para a evidência que resolveria cada item.

| Métrica | Pergunta |
|---|---|
| Tempo de voo real do Full Throw | OQ-01 |
| Ápice real do Full Throw | OQ-02 |
| Aspect ratio / altura visível em u | OQ-03 |
| Ponto de lançamento (offset do cano) e ponto de referência do alvo | OQ-09 |
| Faixa, passo e regra de mudança do vento | OQ-08 |
| Comportamento da barra de força no estouro | OQ-10 |
| Limites de ângulo por arma; ângulo máximo acima de 90°? | OQ-11, OQ-22 |
| Dimensões da hitbox do personagem | OQ-12 |
| Raio de explosão, raio de cratera, curva de dano | OQ-13 |
| Regra de ordem de turno (delay) | OQ-14 |
| Velocidade de movimento, stamina, inclinação máxima | OQ-16 |
| Limite inferior de morte, dimensões de mapa | OQ-17 |
