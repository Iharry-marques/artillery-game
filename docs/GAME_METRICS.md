# Métricas de gameplay

**Fonte canônica (futura) de toda métrica de gameplay.** Código, Blender e HUD devem ler daqui, via
configuração centralizada (`GameMetrics` / `WeaponDefinition`), e não reinventar números.

Regras:
- Nenhum valor sobe de categoria sem evidência registrada em [EVIDENCE_MATRIX.md](EVIDENCE_MATRIX.md).
- **CALIBRATED** exige um teste automatizado que prove o valor contra a simulação real.
- Valores ESTIMATED são provisórios e podem ser trocados sem cerimônia.

Unidade base: **u** = 1 unidade de distância (1/10 da largura visível da câmera). Tempo em segundos.
Ângulos em graus, medidos a partir da horizontal, na direção em que o personagem está virado.

Última revisão: 06/10/2026.

---

## CONFIRMED

Relações de gameplay que o sistema **deve** reproduzir (requisitos, não constantes de implementação).

| Métrica | Valor | Fonte |
|---|---|---|
| Largura visível da câmera | 10 u | E-01 |
| Força do Full Throw | ≈ 95 | E-02 |
| Relação Full Throw, vento 0, desnível 0 | Ângulo ≈ 90 − D (D = 3, 5, 10 são os casos de teste) | E-03 |
| Correção de vento do Full Throw | ≈ 2° por 1,0 de vento (contra → −, a favor → +) | E-04 |
| Vento durante o voo | constante | E-06 |
| Determinismo | mesmo input → mesma trajetória, bit a bit, na mesma plataforma | E-09 |

## CALIBRATED

*Nenhum valor ainda.* Os primeiros candidatos, que sairão do marco 1 (núcleo balístico headless):

| Métrica | Alvo de calibração |
|---|---|
| `power_scale` (u/s por ponto de força) | Minimizar o erro de impacto de 90 − D, D = 1…10, força 95, vento 0 |
| `wind_accel_per_unit` (u/s² por 1,0 de vento) | Correção de 2° no Full Throw |

## ESTIMATED

Derivações analíticas e escolhas provisórias. Detalhes em [PHYSICS_MODEL.md](PHYSICS_MODEL.md).

| Métrica | Valor provisório | Base | Confiança |
|---|---|---|---|
| K = v(95)²/g | 28,6–29,0 u | Derivação analítica de 90 − D (linearização: 28,65; ajuste D = 1…10: 29,03) | MEDIUM |
| Aceleração do vento por unidade | ≈ g / 28,65 (≈ 0,035·g) | Derivação analítica do ×2 | MEDIUM |
| Ápice do Full Throw | ≈ 14 u acima do lançamento (θ = 80) | Consequência de K | MEDIUM |
| Tempo de voo do Full Throw | **escolha de feel**; 4 s como ponto de partida | Define g. Sem memória/medição | LOW |
| Gravidade g | ≈ 7,0 u/s² se tempo de voo = 4 s | g = 4·K·sin²θ/T² | LOW |
| v(95) | ≈ 14,3 u/s se tempo de voo = 4 s | v = √(K·g) | LOW |
| Velocidade por ponto de força | ≈ 0,15 u/s se tempo de voo = 4 s | v(95)/95 | LOW |
| Timestep da simulação | 1/60 s | Escolha de engenharia; casa com o tick padrão do Godot | LOW |
| Escala de apresentação | 1 u = 100 px de mundo | Conveniência (números redondos). Não afeta física | LOW |
| Velocidade de carga da força | 0 → 100 em ~2,5–3,0 s | COMMUNITY RESEARCH | LOW |
| Largura de mapa | ~25–40 u | COMMUNITY RESEARCH | LOW |
| Altura do personagem | ~12–15% da altura visível | COMMUNITY RESEARCH; depende do aspect ratio | LOW |

## UNKNOWN

Ver [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md) para a evidência que resolveria cada item.

| Métrica | Pergunta |
|---|---|
| Tempo de voo real do Full Throw | OQ-01 |
| Aspect ratio / altura visível em u | OQ-03 |
| Ponto de lançamento (offset do cano) e ponto de referência do alvo | OQ-09 |
| Faixa, passo e regra de mudança do vento | OQ-08 |
| Comportamento da barra de força no estouro | OQ-10 |
| Limites de ângulo por arma | OQ-11 |
| Dimensões da hitbox do personagem | OQ-12 |
| Raio de explosão, raio de cratera, curva de dano | OQ-13 |
| Regra de ordem de turno (delay) | OQ-14 |
| Velocidade de movimento, stamina, inclinação máxima | OQ-16 |
| Limite inferior de morte, dimensões de mapa | OQ-17 |
