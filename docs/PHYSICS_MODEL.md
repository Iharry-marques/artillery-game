# Modelo físico do projétil

> **Status: modelo candidato com relações adimensionais CALIBRADAS no simulador real (Marco 1).**
> A forma do modelo (sem arrasto, vento como aceleração horizontal constante, força linear) continua sendo
> hipótese. A escala de tempo (gravidade) continua **ESTIMATED / LOW**.
> Resultados completos e reproduzíveis: [tools/ballistics/reports/calibration_report.md](../tools/ballistics/reports/calibration_report.md).
> Última revisão: 06/10/2026.

## 1. Objetivo

Uma única simulação balística, determinística e aprendível, na qual as técnicas clássicas de mira funcionam
**naturalmente**, sem casos especiais. O Full Throw (força 95, `Ângulo = 90 − D`) é um **teste** da física,
não um ramo dentro dela.

## 2. Convenções

- Unidade de comprimento **u**: 1 unidade horizontal de distância de gameplay = 1,0 unidade de mundo.
  A câmera (futura) mostrará 10 u de largura (D-002). Pixels são só apresentação.
- Eixo y para **baixo** (convenção do Godot). Gravidade positiva em y.
- Ângulo θ em graus a partir da horizontal, na direção `facing = ±1`.
- Vento W: decimal com sinal no referencial do mundo (+ empurra para +x). **Vento relativo** = W·facing:
  positivo é a favor, negativo é contra.

### Geometria de calibração (D-013)

- Atirador em (0, 0). Alvo em (D, 0). Sem offset de cano, sem hitbox, sem raio de projétil.
- **Impacto** = posição x em que o projétil cruza y = 0 **descendo**, após o lançamento. O cruzamento é localizado
  dentro do passo (seção 3.2).
- OQ-09 (ponto de lançamento/referência do personagem) continua importante para o jogo, mas não afeta este núcleo.

## 3. Modelo implementado

```
initial_speed = power_model.initial_speed(power)     # hoje: power * power_scale (LinearPowerModel)
vx0 =  facing * initial_speed * cos(θ)
vy0 = -initial_speed * sin(θ)
a   = (wind * wind_accel_per_unit, gravity)           # constante durante todo o voo
```

### 3.1 Integrador baseline: cinemática exata para aceleração constante (D-012)

```
next_position = position + velocity * dt + 0.5 * acceleration * dt²
next_velocity = velocity + acceleration * dt
```

Como a aceleração é constante, cada passo cai **exatamente** na parábola analítica. A trajetória não depende do dt.
Isso foi verificado em teste (seção 7). O integrador é uma estratégia (`BallisticIntegrator`), então um integrador
discreto "legado" (ex.: Euler semi-implícito) pode ser adicionado e comparado se surgir evidência de que o erro de
integração fazia parte do comportamento histórico.

> Versão anterior deste documento propunha Euler semi-implícito. Substituída por D-012: não há evidência de que o erro
> de timestep histórico importe, e queremos a trajetória matemática independente do dt.

### 3.2 Ápice e cruzamento dentro do passo

Quando a velocidade vertical muda de sinal dentro de um passo, o ápice é localizado por bisseção do tempo do
sub-passo, usando o **próprio integrador** (`advance(state, τ)`). O cruzamento descendente com o plano só pode ocorrer
**depois** do ápice, e é localizado da mesma forma. Isso cobre o caso em que o projétil sobe e desce dentro de um único
passo. Esse caso era um bug da primeira versão: tiros muito fracos eram classificados como "sem subida" de forma
dependente do dt. Há teste de regressão.

### 3.3 Terminações

| Terminação | Significado |
|---|---|
| `IMPACT_PLANE` | Cruzou o plano descendo |
| `NO_ASCENT` | Está no plano ou abaixo dele, descendo, sem ter cruzado: nunca mais sobe |
| `MAX_TIME` | Atingiu o limite de segurança de tempo de voo |

### 3.4 Fora do modelo, de propósito

Arrasto aerodinâmico, massa, vento vertical, rotação, aleatoriedade, motor de física do Godot (RigidBody2D), frames de
física ou de render.

## 4. Implementação

| Arquivo | Papel |
|---|---|
| `godot/scripts/core/ballistics/projectile_simulation.gd` | `ProjectileSimulation.simulate_to_plane()`: lógica pura, sem nós |
| `.../projectile_state.gd` | Estado (x, y, vx, vy, t) em escalares de 64 bits (Vector2 é float32) |
| `.../ballistic_integrator.gd`, `exact_kinematic_integrator.gd` | Estratégia de integração + baseline exata |
| `.../power_model.gd`, `linear_power_model.gd` | Único lugar onde força vira velocidade |
| `.../shot_parameters.gd`, `ballistic_parameters.gd`, `ballistic_result.gd` | Entradas e saídas |
| `godot/scripts/core/game_metrics.gd` + `godot/config/game_metrics.tres` | Constantes centralizadas |
| `godot/scripts/core/aiming/ballistic_solver.gd` | Perguntas inversas (que ângulo/força acerta D?). Só prevê |
| `godot/calibration/` | Evidência de referência, calibrador e ferramenta de relatório |

O resultado (`BallisticResult`) traz impacto, tempo de voo, ápice (posição e tempo), amostras da trajetória,
velocidade de lançamento, número de passos e terminação.

## 5. Calibração (o que as evidências fixam)

As evidências fixam **razões**, não três constantes independentes. Por isso o `GameMetrics` guarda:

| Grandeza | Classe | Valor |
|---|---|---|
| `K = v(95)² / g` | **CALIBRATED** (relação adimensional) | **29,033036 u** |
| `wind_accel_ratio` = aceleração do vento por 1,0 de vento ÷ g | **CALIBRATED** (relação adimensional) | **0,034401** (= g / 29,07) |
| `gravity` | **ESTIMATED / LOW** (escala de tempo) | 7,039396 u/s² |

Derivados, nunca armazenados: `power_scale = √(K·g) / 95` = 0,150484 u/s por ponto; `v(95)` = 14,296 u/s;
aceleração do vento = `ratio·g` = 0,242162 u/s² por 1,0 de vento. **Se a gravidade mudar, esses três mudam; os pontos
de impacto não.** Há teste comprovando isso para g = 1; 3; 7,04; 12,5.

### 5.1 Métrica de erro e método

- **K:** mínimos quadrados de `impacto(θ = 90 − D, força 95, vento 0) − D` para D = 1…10, todos com o mesmo peso.
  Resolvido por Gauss-Newton com derivada numérica, rodando o simulador.
- **Vento:** mínimos quadrados de `(θ_vento − θ_0) − 2·W` para D = 3…10 e W = ±1,0, em que θ_0 e θ_vento são os ângulos
  que **realmente** acertam D (resolvidos pelo simulador). D = 1 e 2 ficaram de fora porque, com vento a favor, a
  solução exige ângulo acima de 90° (OQ-22).
- **Verificação independente:** a forma fechada `K = Σ D·sin 2θ / Σ sin² 2θ` dá 29,033036395. A diferença para o
  simulador é de 2,1e-10.

### 5.2 Full Throw sem vento (força 95, ângulo = 90 − D)

| D | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Impacto | 1,0132 | 2,0252 | 3,0348 | 4,0406 | 5,0415 | 6,0363 | 7,0237 | 8,0026 | 8,9717 | 9,9299 |
| Erro (u) | +0,013 | +0,025 | +0,035 | +0,041 | +0,042 | +0,036 | +0,024 | +0,003 | −0,028 | −0,070 |

**Erro absoluto médio 0,0316 u · máximo 0,0701 u (D = 10) · RMS 0,0361 u.**

O erro é estrutural, e não ruído: a regra linear `90 − D` aproxima `K·sin(2D)`. Nenhum K único zera todas as distâncias.
Com 1 u = 100 px, o pior erro equivale a ~7 px.

## 6. Tolerâncias dos testes (escolhidas depois de medir)

Ficam em `godot/tests/support/ballistic_tolerances.gd`. São guardas de regressão logo acima do erro medido, não alvos.

| Verificação | Medido | Tolerância |
|---|---|---|
| Impacto do Full Throw, cada D | máx. 0,0701 u | 0,075 u |
| Erro absoluto médio, D = 1…10 | 0,0316 u | 0,035 u |
| Correção de vento vs. regra ×2 | máx. 0,0353° | 0,04° |
| Impacto mirando com `90 − D + 2·W`, \|W\| ≤ 1, D = 3, 5, 10 | máx. 0,1024 u | 0,11 u |
| Equivalência numérica (timestep, determinismo, forma fechada) | ≤ 1,5e-13 | 1e-9 |

## 7. Invariância de timestep

Impacto com dt = 1/30, 1/60 e 1/120 para Full Throw D = 3, 5, 10, Full Throw com vento contra e um tiro de 30° com
vento a favor: diferença máxima de **1,5e-13 u**, só arredondamento. Tempo de voo e ápice também são invariantes (teste).

## 8. Escala de tempo (provisória)

A gravidade foi escolhida para que o Full Throw em D = 10 dure **4,0 s** (D-010, ESTIMATED / LOW). O simulador mede
4,000000 s. Consequência independente de g: o ápice fica **14,08 u** acima do lançamento, em x = 4,96. Isso é testável em
vídeo (OQ-02).

| Tempo de voo (D = 10) | g (u/s²) | power_scale | Vento por 1,0 (u/s²) |
|---|---|---|---|
| 3 s | 12,5145 | 0,200645 | 0,430510 |
| **4 s (atual)** | **7,0394** | **0,150484** | **0,242162** |
| 5 s | 4,5052 | 0,120387 | 0,154984 |
| 6 s | 3,1286 | 0,100323 | 0,107628 |

## 9. Vento no Full Throw

Correção medida (ângulo que acerta com vento − ângulo que acerta sem vento), por 1,0 de vento:

| D | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|
| Correção | 1,976 | 1,980 | 1,985 | 1,992 | 2,000 | 2,010 | 2,021 | 2,035 |

Erro máximo vs. regra ×2: 0,035°. Contra e a favor diferem no máximo 0,002°. Mirando direto com a regra
inteira `90 − D + 2·W`, o erro de impacto chega a 0,10 u com |W| = 1 e a 0,13 u com |W| = 2 (D = 10, vento contra),
porque o erro sem vento e o erro de vento se somam.

## 10. Previsões para outras técnicas (mesmo modelo, sem ajuste)

Correção de ângulo que compensa 1,0 de vento com a mesma força, e correção de força alternativa com o mesmo ângulo.
Os valores de ângulo independem da distância, como a análise previa.

| Técnica | Força sem vento (D = 1 / 3 / 5 / 10) | Vento contra: Δângulo | A favor: Δângulo | Média \|Δ\| | Comunidade | Δforça por 1,0 de vento (D = 1 → 10) |
|---|---|---|---|---|---|---|
| 20° | 22,0 / 38,1 / 49,2 / 69,5 | +0,311 | −0,291 | 0,30 | sem dado | ±0,14 → ±0,44 |
| 30° | 19,0 / 32,8 / 42,4 / 59,9 | +1,087 | −0,907 | **1,00** | ×1 | ±0,19 → ±0,60 |
| 50° | 17,8 / 30,8 / 39,7 / 56,2 | **sem solução** | +5,097 | — | ×2 | +0,38 → +1,19 / −0,35 → −1,12 |
| 65° | 20,1 / 34,9 / 45,0 / 63,7 | −2,549 | +2,491 | **2,52** | ×2 | +0,79 → +2,49 / −0,70 → −2,23 |

Leitura (as divergências são **evidência**, não bug):
- **30°:** o modelo dá ×1,00 em média. Esse fator nunca foi usado na calibração, o que o torna a confirmação
  independente mais forte do modelo. A assimetria (1,09 contra, 0,91 a favor) é efeito não linear previsto.
- **65°:** o modelo dá ×2,5, contra ×2 da comunidade. Ou a fonte arredondava, ou o modelo de vento está incompleto (OQ-05).
- **50°:** com vento contra **não existe** ângulo no ramo alto que compense. O ângulo de 50° está perto do alcance
  máximo (45°), onde mudar o ângulo quase não muda o alcance. Uma técnica de 50° com "±2·vento" no ângulo é
  fisicamente incoerente com este modelo; o mais provável é que compensasse pela força (OQ-05).
- **Tabela de força de 30°:** o modelo pede 18,95 / 42,36 / 59,91 para D = 1 / 5 / 10, contra 14 / 32 / 47,5 da
  comunidade (razão 1,35 / 1,32 / 1,26). A razão não é constante, então a diferença não é só de escala (OQ-04).

## 11. Half Throw (não calibrado)

Regra candidata `Ângulo = 90 − 2·D`. A força que melhor a reproduz (mínimos quadrados, D = 1…10) é **68,5**. A força
exata por distância vai de 66,8 (D = 1) a 69,5 (D = 10). A pesquisa diz **≈ 60**. Com força 60, o modelo cai ~19–26%
curto, e a regra que funcionaria seria ≈ 2,5–3,0° por unidade, não 2. **Discrepância registrada (OQ-06); a física não
foi alterada.**

## 12. Constantes e status

| Constante | Status | Origem |
|---|---|---|
| K | CALIBRATED | Full Throw D = 1…10, mínimos quadrados |
| `wind_accel_ratio` | CALIBRATED | Regra ×2 do Full Throw, D = 3…10, W = ±1 |
| `gravity` | ESTIMATED / LOW | Tempo de voo provisório de 4 s (sem evidência de gameplay) |
| `power_scale`, aceleração do vento | derivados | de K / ratio e gravity |
| Mapeamento força → velocidade | hipótese (linear) | isolado em `PowerModel` |
| `time_step` | engenharia (1/60) | não afeta impactos (seção 7) |
| `max_flight_time` | engenharia (30 s) | limite de segurança |
| Offset de cano, ponto de referência do alvo, raio do projétil | UNKNOWN | OQ-09 (fora do núcleo) |

## 13. Riscos e limites

- O ajuste é bom (≤ 0,07 u) **dentro** de D = 1…10. Para D > 12 a regra `90 − D` degrada em balística pura (OQ-07).
- Ângulos acima de 90° aparecem como solução matemática (D = 1–2 com vento a favor; D = 3 com +2). Se o jogo limitar a
  90°, a regra de vento falha nesses casos (OQ-22).
- Determinismo verificado na mesma máquina/build. Entre plataformas não foi verificado (irrelevante sem rede).
- Tunelamento: o plano de calibração não sofre disso (cruzamento por sub-passo), mas o terreno futuro precisará de
  teste por segmento com o mesmo cuidado.

## 14. Como reproduzir

```bash
export GODOT=/caminho/para/Godot     # opcional se o Godot estiver no PATH ou em /Applications
tools/ballistics/calibrate.sh                  # gera o relatório
tools/ballistics/calibrate.sh --write-metrics  # também regrava godot/config/game_metrics.tres
tools/run_tests.sh                             # checagem estática + 20 testes headless
```

## Apêndice: derivação analítica (Marco 0, mantida como referência)

Sem arrasto e em solo plano, `R = (v²/g)·sin 2θ`. Com θ = 90 − D, `sin 2θ = sin 2D ≈ 2D·π/180`, o que dá `K ≈ 90/π ≈ 28,65`
na linearização; o ajuste em D = 1…10 dá 29,03, que é o valor confirmado pelo simulador. Para o vento, com a correção em
graus `δθ = (180/π)·(a_w/g)·sin²θ/|cos 2θ|`, o fator ×2 em θ → 90 dá `a_w/g ≈ 1/28,65`. A calibração no simulador, em
D = 3…10, deu 1/29,07. A previsão `k(θ) = 2·sin²θ/|cos 2θ|` (1,0 em 30°; 2,56 em 65°; 6,8 em 50°) é a versão linearizada
da seção 10.
