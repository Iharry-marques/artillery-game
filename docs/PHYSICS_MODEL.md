# Modelo físico do projétil: hipótese candidata

> **Status: CANDIDATO.** Não está declarado correto. Precisa ser calibrado experimentalmente contra as
> relações conhecidas (GAME_METRICS → CONFIRMED) usando a simulação real, com testes automatizados.
> Última revisão: 06/10/2026.

## 1. Objetivo

Uma única simulação balística, determinística e aprendível, na qual as técnicas clássicas de mira
**funcionam naturalmente**, sem casos especiais. A técnica de calibração primária é o Full Throw:
força 95, vento 0, desnível 0 → `Ângulo = 90 − Distância`.

## 2. Convenções

- Unidade de comprimento: **u** (1 unidade de distância = 1/10 da largura visível da câmera). A conversão para
  pixels é só de apresentação.
- Eixo y para **baixo** (convenção do Godot). Gravidade positiva em y.
- Ângulo θ em graus, de 0 a 90, a partir da horizontal, na direção em que o atirador está virado (`facing = ±1`).
- Vento W: decimal com sinal no referencial do mundo (+ empurra para +x). "Contra" e "a favor" dependem de `facing`.

## 3. Modelo candidato

Estado: posição `p = (x, y)`, velocidade `v = (vx, vy)`.

```
initial_speed = power * power_scale
vx0 = facing * initial_speed * cos(θ)
vy0 = -initial_speed * sin(θ)

a_x = wind * wind_accel_per_unit       # vento: aceleração horizontal constante
a_y = gravity                          # gravidade constante

loop a cada passo fixo dt:              # integrador candidato: Euler semi-implícito
    vx += a_x * dt
    vy += a_y * dt
    x  += vx * dt
    y  += vy * dt
    testar colisão no SEGMENTO (p_anterior → p), não só no ponto
```

Fora do modelo, de propósito: arrasto aerodinâmico, massa, vento vertical, rotação, aleatoriedade e o motor
de física do Godot (RigidBody2D).

Solução fechada (aceleração constante, usada só para análise):

```
x(t) = x0 + vx0·t + ½·a_x·t²
y(t) = y0 + vy0·t + ½·g·t²
```

## 4. O que as relações conhecidas determinam (ENGINEERING INFERENCE)

Script de verificação usado nesta análise: cálculo analítico em Python, fora do repositório. A versão
versionada virá no marco 1 em `tools/ballistics/`.

### 4.1 Full Throw gera 90 − D naturalmente

Em solo plano, sem vento: `R = (v²/g)·sin(2θ)`. Com `θ = 90 − D`: `sin(2θ) = sin(180 − 2D) = sin(2D)`.
Para D pequeno, `sin(2D°) ≈ 2D·π/180`, linear em D. Portanto:

```
R ≈ D  ⇔  K := v(95)²/g = 90/π ≈ 28,65 u        (linearização em θ → 90)
          K ≈ 29,03 u                            (mínimos quadrados, D = 1…10)
```

Impacto previsto com K = 29,03:

| D | 1 | 3 | 5 | 8 | 10 | 15 | 20 |
|---|---|---|---|---|---|---|---|
| alcance (u) | 1,01 | 3,03 | 5,04 | 8,00 | 9,93 | 14,52 | 18,66 |

Conclusão: a regra do jogador é **compatível com balística pura sem arrasto** e erra ≤ 0,07 u em D = 1…10.
Previsão falsificável: a regra degrada para D > ~12 (OQ-07).

### 4.2 O fator de vento ×2 fixa a aceleração do vento

Vento horizontal não altera o tempo de voo `T = 2·v·sinθ/g`. O deslocamento extra é `½·a_x·T²`.
A sensibilidade do alcance ao ângulo é `dR/dθ = 2·(v²/g)·cos 2θ`. A correção em graus que anula o vento é:

```
δθ = (180/π) · (a_x/g) · sin²θ / |cos 2θ|
```

Exigindo 2° por 1,0 de vento com θ → 90:

```
wind_accel_per_unit ≈ g · 2·π/180 = g / 28,65 ≈ 0,0349·g
```

Verificação não linear (busca do ângulo exato com vento contra 1,0, K = 29,03): D 3 → 1,97° · D 5 → 1,97° · D 10 → 2,14°.

### 4.3 Previsão: fator de vento por técnica

Com `wind_accel_per_unit = g/28,65`, o fator de correção é **independente de força e distância** e depende só do
ângulo da técnica:

```
k(θ) = 2 · sin²θ / |cos 2θ|        (graus por 1,0 de vento)
```

| θ | 87 | 85 | 80 | 75 | 65 | 50 | 30 | 20 |
|---|---|---|---|---|---|---|---|---|
| k | 2,01 | 2,02 | 2,06 | 2,15 | 2,56 | 6,76 | **1,00** | 0,31 |

- O ×1 da técnica de 30° (COMMUNITY RESEARCH) é previsto **sem ter sido usado na calibração**. É a evidência mais forte a favor do modelo até agora.
- 65° (comunidade: ×2) e 50° (comunidade: ×2) conflitam. Perto de 45° o alcance quase não depende do ângulo, então
  uma técnica de 50° provavelmente compensava o vento pela força, ou a fonte está errada (OQ-05).
- Sinal: para θ > 45, vento contra → diminuir ângulo; para θ < 45, vento contra → aumentar ângulo.

### 4.4 Velocidade linear na força

Tabela de 30° (COMMUNITY RESEARCH): D 1 → 14, D 5 → 32, D 10 → 47,5. Ajuste `D ∝ P^n` dá n ≈ 1,88–1,95,
próximo de 2. Isso é compatível com `v ∝ P` e `R ∝ v²`; o pequeno desvio pode vir da altura do cano.

Magnitude: calibrado pelo Full Throw, o modelo prevê para 30° as forças 18,9 / 42,4 / 59,9, contra 14 / 32 / 47,5
na tabela (≈ 25% menos). Hipóteses: tabela de outra versão ou arma, força do high throw diferente de 95,
mapeamento força → velocidade não linear, ou erro da fonte. **Não resolvido** (OQ-04).

### 4.5 Half Throw

Fonte: força ≈ 60, `Ângulo = 90 − 2D`. Pelo modelo, a regra 90 − 2D exige `v²/g = K/2`, isto é,
força = 95/√2 ≈ **67**. Com força 60, o modelo prevê ≈ 2,5° por unidade, não 2. **Conflito** (OQ-06).

### 4.6 Graus de liberdade restantes

As relações conhecidas fixam **razões**: `v(95)²/g` e `a_vento/g`. Sobram:

1. **Escala de tempo** (g em u/s²). Define a duração do voo e, portanto, o *feel*. Não afeta onde o tiro cai.
2. **Escala de apresentação** (px por u). Puramente visual.

| Tempo de voo do Full Throw (θ = 80) | g (u/s²) | v(95) (u/s) | vento por unidade (u/s²) |
|---|---|---|---|
| 3 s | 12,51 | 19,06 | 0,437 |
| **4 s (provisório)** | **7,04** | **14,30** | **0,246** |
| 5 s | 4,51 | 11,44 | 0,157 |
| 6 s | 3,13 | 9,53 | 0,109 |

Consequência independente de g: o ápice do Full Throw fica ≈ **14 u** acima do ponto de lançamento,
bem acima do topo da tela. Isso é coerente com o "tiro que some para cima" típico do gênero e pode ser
verificado em vídeo (OQ-02).

## 5. Constantes a resolver

| Constante | Como resolver | Status |
|---|---|---|
| `power_scale` | Calibração: minimizar erro de 90 − D (D = 1…10) no integrador real, dado g | ESTIMATED |
| `gravity` | Escolha de feel ancorada no tempo de voo real do Full Throw (vídeo/memória) | ESTIMATED / LOW |
| `wind_accel_per_unit` | Calibração: correção de 2° no Full Throw; validar o ×1 aos 30° | ESTIMATED |
| `dt` | Escolha de engenharia (1/60). Recalibrar `power_scale` se mudar | ESTIMATED |
| Mapeamento força → velocidade | Linear até prova em contrário; testar com tabelas de outras técnicas | ESTIMATED |
| Ponto de lançamento (offset do cano) | Importa em D pequeno; medir em vídeo ou definir por design + recalibrar | UNKNOWN |
| Ponto de referência do alvo (pés/centro) | Define o que significa "acertar" no teste | UNKNOWN |
| Raio de colisão do projétil | Afeta impacto em terreno inclinado | UNKNOWN |
| Limites de ângulo por arma | Pesquisa; não afeta a física | UNKNOWN |

## 6. Riscos e cuidados

- **Integrador ≠ fórmula fechada.** Euler semi-implícito com dt = 1/60 tem erro de O(dt). Por isso a calibração
  roda **no integrador real** (D-004), e o resultado analítico serve só de chute inicial.
- **Tunelamento.** Com v ≈ 14 u/s e dt = 1/60, o projétil anda ≈ 0,24 u por passo. A colisão precisa ser testada por segmento.
- **Determinismo.** Floats de 64 bits no GDScript são determinísticos na mesma plataforma/build. Determinismo entre
  plataformas só importa se houver rede (fora do escopo). A simulação não pode depender de `delta` variável,
  de frame rate ou da ordem de nós.
- **Desnível vertical.** As regras conhecidas assumem desnível 0. Com desnível, o tiro cai mais longe ou mais curto.
  O Lab deve medir isso, não corrigi-lo na física.

## 7. Plano de calibração (marco 1)

1. Implementar a simulação pura em GDScript (sem Node), parametrizada por `GameMetrics`.
2. Solver headless: dado g e dt, encontrar `power_scale` que minimiza o erro máximo de 90 − D para D = 1…10.
3. Encontrar `wind_accel_per_unit` para 2° no Full Throw (D = 3, 5, 10).
4. Testes automatizados: D 10/80, D 5/85, D 3/87 (força 95, vento 0) caem dentro de uma tolerância
   (proposta: 0,2 u, cerca de meia largura de personagem pela estimativa LOW da pesquisa; revisar quando a hitbox for definida).
5. Relatório de previsões: fator de vento em 65°, 50°, 30° e 20°, tabela de força de 30° e Half Throw,
   para comparar com as fontes e fechar OQ-04/05/06.
