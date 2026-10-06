# Matriz de evidências

Cada afirmação relevante de gameplay, com origem e confiança. Atualize quando uma calibração, medição ou
memória nova mudar a confiança. Última revisão: 06/10/2026 (Marco 1).

**Confiança:** HIGH (múltiplas fontes concordantes ou verificação direta) · MEDIUM (uma fonte forte ou dedução sólida) · LOW (fonte única fraca, sem derivação).
**Tipos:** PLAYER VERIFIED · COMMUNITY RESEARCH · CALIBRATED · ENGINEERING INFERENCE · UNKNOWN.

| # | Mecânica | Afirmação | Tipo de evidência | Confiança | Precisa validar | Observações |
|---|---|---|---|---|---|---|
| E-01 | Distância | 1 largura de tela visível ≈ 10 unidades de distância | PLAYER VERIFIED + COMMUNITY RESEARCH | HIGH | Não (conceito) | Medida horizontal. Implementar como constante de mundo + câmera travada em 10 unidades (D-002). |
| E-02 | Full Throw | Força ≈ 95 | PLAYER VERIFIED | HIGH | Sim, a constante exata | "≈": pode ter sido 94–96 ou diferente entre versões (95 vs 100, E-14). |
| E-03 | Full Throw | Vento 0: Ângulo ≈ 90 − Distância | PLAYER VERIFIED + CALIBRATED | HIGH | Não (para D = 1…10) | Reproduzida pelo simulador com K = 29,033 u: erro médio 0,032 u, máx. 0,070 u (D = 10). Teste automatizado. |
| E-04 | Full Throw | Correção de vento ≈ Vento × 2 graus | PLAYER VERIFIED + CALIBRATED | HIGH | Não | Simulador com `wind_accel_ratio` = 0,034401: correção de 1,976° (D = 3) a 2,035° (D = 10), erro máx. 0,035°. Contra → diminui; a favor → aumenta. |
| E-05 | Vento | O fator de correção difere entre técnicas | PLAYER VERIFIED + CALIBRATED | HIGH | Não | O mesmo modelo dá ×0,30 (20°), ×1,00 (30°), ×2,52 (65°) e ×2,0 (Full Throw). |
| E-06 | Vento | Vento é constante durante o voo | PLAYER VERIFIED | HIGH | Não | Muda apenas entre turnos (COMMUNITY). |
| E-07 | Vento | Exibido como decimal; faixa ~0–5 | PLAYER VERIFIED (decimal) / COMMUNITY RESEARCH (faixa) | MEDIUM | Sim, faixa e passo | OQ-08. |
| E-08 | Força | Faixa ≈ 0–100 | PLAYER VERIFIED (indireto) + COMMUNITY RESEARCH | MEDIUM | Sim | Inferida de "95 é quase o máximo". Comportamento no estouro desconhecido (OQ-10). |
| E-09 | Física | Física do projétil é determinística | PLAYER VERIFIED (previsibilidade) + ENGINEERING INFERENCE | HIGH | Não | Requisito de projeto, além de fato histórico. |
| E-10 | Física | Velocidade inicial é linear na força | ENGINEERING INFERENCE + COMMUNITY RESEARCH | MEDIUM | Sim | Formato da tabela de 30° sustenta (alcance ∝ força^1,9). Magnitude conflita (E-13). |
| E-11 | Vento | Vento = aceleração horizontal constante; 1,0 de vento = 0,034401·g | CALIBRATED (valor) + ENGINEERING INFERENCE (forma) | MEDIUM | Sim, a forma | Valor calibrado no Full Throw; prevê o ×1 de 30° sem ajuste. A forma (constante, só horizontal) segue hipótese (D-009). |
| E-12 | Física | Sem arrasto aerodinâmico; gravidade constante | COMMUNITY RESEARCH + ENGINEERING INFERENCE | MEDIUM | Sim | Necessário para 90 − D surgir naturalmente. Arrasto quebraria a linearidade. |
| E-13 | Técnica 30° | Força: D1 → 14, D5 → 32, D10 → 47,5; ângulo 30 ± vento | COMMUNITY RESEARCH | LOW | Sim | Fator de vento confirmado pelo modelo (×1,00). Força: o modelo pede 18,95 / 42,36 / 59,91 (razão 1,35 → 1,26, não constante) (OQ-04). |
| E-14 | Força | Força "universal" do high throw: 95 (clássico) vs 100 (versões posteriores) | COMMUNITY RESEARCH | LOW | Sim | Adotamos 95 (memória do jogador, era clássica). |
| E-15 | Half Throw | Força ≈ 60; Ângulo = 90 − 2·D | COMMUNITY RESEARCH | LOW | Sim | Modelo: melhor força 68,5 (66,8–69,5 por D). Com 60, cai 19–26% curto (OQ-06). |
| E-16 | Técnica 65° | Ângulo = 65 ± 2·Vento | COMMUNITY RESEARCH | LOW | Sim | Modelo: ×2,52 (2,55 contra / 2,49 a favor) (OQ-05). |
| E-17 | Técnica 50° | Ângulo = 50 ± 2·Vento | COMMUNITY RESEARCH | LOW | Sim | Modelo: com vento contra, nenhum ângulo do ramo alto compensa; a favor, +5,1°. Compensação por força: ±0,4–1,2 por 1,0 de vento (OQ-05). |
| E-18 | Tela | Área de jogo clássica 800×600 ou 1000×600 | COMMUNITY RESEARCH | LOW | Opcional | Fonte se contradiz. Só afeta a altura visível (OQ-03). |
| E-19 | Física | Timestep 30 Hz, integração Euler | COMMUNITY RESEARCH | LOW | Não precisa replicar | Substituído por integrador exato de aceleração constante (D-012); impactos independem do dt. |
| E-20 | Física | Gravidade ≈ 450 px/s²; 12,5 px/s por força; vento 20 px/s² | COMMUNITY RESEARCH | LOW | — | Sem derivação. **Não usar.** Com 1 un = 100 px, dariam v(95)²/g ≈ 31,3 un (próximo de 28,6!) e vento ≈ g/22,5 (vs g/28,65). Coincidência parcial a investigar. |
| E-21 | Alcance | Full Throw: ápice ≈ 14 u acima do lançamento | ENGINEERING INFERENCE (medido no simulador) | MEDIUM | Sim, por vídeo | Simulador: 14,08 u em D = 10, independente de g. Bom teste de falsificação (OQ-02). |
| E-22 | Full Throw | A regra 90 − D degrada para D > ~12 | ENGINEERING INFERENCE | MEDIUM | Sim, memória/vídeo | Com K = 29,03: D 15 → ~14,5; D 20 → ~18,7 (OQ-07). |
| E-23 | Personagem | Hitbox única, sem multiplicador por parte do corpo | COMMUNITY RESEARCH | MEDIUM | Opcional | Coerente com a experiência típica do gênero. |
| E-24 | Turno | Ordem por atraso (delay), não alternância | COMMUNITY RESEARCH | MEDIUM | Sim | Valores numéricos contraditórios na fonte (OQ-14). |
| E-25 | Terreno | Destrutível por subtração circular; sem gravidade de terreno | COMMUNITY RESEARCH | MEDIUM | Sim | Implementação (polígono vs bitmap) é decisão nossa (OQ-15). |
| E-26 | Mira | Ângulo em passos de 1°; limites dependem da arma | COMMUNITY RESEARCH | MEDIUM | Sim | Os valores das tabelas são inteiros, o que é coerente com passo de 1°. |
| E-27 | Física | Trajetória independe do timestep | CALIBRATED (verificado) | HIGH | Não | dt = 1/30, 1/60, 1/120: diferença de impacto ≤ 1,5e-13 u (D-012). |
| E-28 | Física | Com K fixo, os pontos de impacto independem da gravidade | CALIBRATED (verificado) | HIGH | Não | Testado com g = 1; 3; 7,04; 12,5. A gravidade só define a escala de tempo. |
| E-29 | Full Throw | A regra de vento exige ângulo > 90° em D pequeno com vento a favor | ENGINEERING INFERENCE | MEDIUM | Sim | 91° em D = 1 (W +1), D = 2 (W +1,5), D = 3 (W +2) (OQ-22). |
