# Matriz de evidências

Cada afirmação relevante de gameplay, com origem e confiança. Atualize quando uma calibração, medição ou
memória nova mudar a confiança. Última revisão: 06/10/2026.

**Confiança:** HIGH (múltiplas fontes concordantes ou verificação direta) · MEDIUM (uma fonte forte ou dedução sólida) · LOW (fonte única fraca, sem derivação).
**Tipos:** PLAYER VERIFIED · COMMUNITY RESEARCH · CALIBRATED · ENGINEERING INFERENCE · UNKNOWN.

| # | Mecânica | Afirmação | Tipo de evidência | Confiança | Precisa validar | Observações |
|---|---|---|---|---|---|---|
| E-01 | Distância | 1 largura de tela visível ≈ 10 unidades de distância | PLAYER VERIFIED + COMMUNITY RESEARCH | HIGH | Não (conceito) | Medida horizontal. Implementar como constante de mundo + câmera travada em 10 unidades (D-002). |
| E-02 | Full Throw | Força ≈ 95 | PLAYER VERIFIED | HIGH | Sim, a constante exata | "≈": pode ter sido 94–96 ou diferente entre versões (95 vs 100, E-14). |
| E-03 | Full Throw | Vento 0: Ângulo ≈ 90 − Distância | PLAYER VERIFIED | HIGH | Sim, por teste automatizado | Reproduzida analiticamente por balística sem arrasto se v(95)²/g ≈ 28,6–29,0 un. (E-10). |
| E-04 | Full Throw | Correção de vento ≈ Vento × 2 graus | PLAYER VERIFIED | HIGH | Sim | Modelo prevê 2,0–2,06 entre 87° e 80° (E-11). Contra → diminui ângulo; a favor → aumenta. |
| E-05 | Vento | O fator de correção difere entre técnicas | PLAYER VERIFIED | HIGH | Não | Explicado pela física: k(θ) = 2·sin²θ/\|cos 2θ\| (E-11). |
| E-06 | Vento | Vento é constante durante o voo | PLAYER VERIFIED | HIGH | Não | Muda apenas entre turnos (COMMUNITY). |
| E-07 | Vento | Exibido como decimal; faixa ~0–5 | PLAYER VERIFIED (decimal) / COMMUNITY RESEARCH (faixa) | MEDIUM | Sim, faixa e passo | OQ-08. |
| E-08 | Força | Faixa ≈ 0–100 | PLAYER VERIFIED (indireto) + COMMUNITY RESEARCH | MEDIUM | Sim | Inferida de "95 é quase o máximo". Comportamento no estouro desconhecido (OQ-10). |
| E-09 | Física | Física do projétil é determinística | PLAYER VERIFIED (previsibilidade) + ENGINEERING INFERENCE | HIGH | Não | Requisito de projeto, além de fato histórico. |
| E-10 | Física | Velocidade inicial é linear na força | ENGINEERING INFERENCE + COMMUNITY RESEARCH | MEDIUM | Sim | Formato da tabela de 30° sustenta (alcance ∝ força^1,9). Magnitude conflita (E-13). |
| E-11 | Vento | Vento = aceleração horizontal constante, ≈ g/28,65 por unidade de vento | ENGINEERING INFERENCE | MEDIUM | Sim | Derivado do ×2 do high throw; prevê de forma independente o ×1 da técnica de 30°. |
| E-12 | Física | Sem arrasto aerodinâmico; gravidade constante | COMMUNITY RESEARCH + ENGINEERING INFERENCE | MEDIUM | Sim | Necessário para 90 − D surgir naturalmente. Arrasto quebraria a linearidade. |
| E-13 | Técnica 30° | Força: D1 → 14, D5 → 32, D10 → 47,5; ângulo 30 ± vento | COMMUNITY RESEARCH | LOW | Sim | Fator de vento bate com o modelo. Força ≈ 25% abaixo do previsto pela calibração do high throw (OQ-04). |
| E-14 | Força | Força "universal" do high throw: 95 (clássico) vs 100 (versões posteriores) | COMMUNITY RESEARCH | LOW | Sim | Adotamos 95 (memória do jogador, era clássica). |
| E-15 | Half Throw | Força ≈ 60; Ângulo = 90 − 2·D | COMMUNITY RESEARCH | LOW | Sim | Modelo exige força ≈ 67 para 90 − 2D (OQ-06). |
| E-16 | Técnica 65° | Ângulo = 65 ± 2·Vento | COMMUNITY RESEARCH | LOW | Sim | Modelo prevê fator ≈ 2,56 (OQ-05). |
| E-17 | Técnica 50° | Ângulo = 50 ± 2·Vento | COMMUNITY RESEARCH | LOW | Sim | Modelo prevê ≈ 6,8; perto de 45° o ângulo quase não muda o alcance. Provavelmente a técnica compensava pela força (OQ-05). |
| E-18 | Tela | Área de jogo clássica 800×600 ou 1000×600 | COMMUNITY RESEARCH | LOW | Opcional | Fonte se contradiz. Só afeta a altura visível (OQ-03). |
| E-19 | Física | Timestep 30 Hz, integração Euler | COMMUNITY RESEARCH | LOW | Não precisa replicar | Nosso dt é escolha de engenharia; calibramos sobre o nosso integrador (D-004). |
| E-20 | Física | Gravidade ≈ 450 px/s²; 12,5 px/s por força; vento 20 px/s² | COMMUNITY RESEARCH | LOW | — | Sem derivação. **Não usar.** Com 1 un = 100 px, dariam v(95)²/g ≈ 31,3 un (próximo de 28,6!) e vento ≈ g/22,5 (vs g/28,65). Coincidência parcial a investigar. |
| E-21 | Alcance | Full Throw prevê ápice ≈ 14 unidades acima do lançamento | ENGINEERING INFERENCE | MEDIUM | Sim, por vídeo | Consequência direta de v²/g ≈ 28,6. Independe da gravidade escolhida. Bom teste de falsificação (OQ-02). |
| E-22 | Full Throw | A regra 90 − D degrada para D > ~12 | ENGINEERING INFERENCE | MEDIUM | Sim, memória/vídeo | D 15 → 14,5; D 20 → 18,7 em balística pura (OQ-07). |
| E-23 | Personagem | Hitbox única, sem multiplicador por parte do corpo | COMMUNITY RESEARCH | MEDIUM | Opcional | Coerente com a experiência típica do gênero. |
| E-24 | Turno | Ordem por atraso (delay), não alternância | COMMUNITY RESEARCH | MEDIUM | Sim | Valores numéricos contraditórios na fonte (OQ-14). |
| E-25 | Terreno | Destrutível por subtração circular; sem gravidade de terreno | COMMUNITY RESEARCH | MEDIUM | Sim | Implementação (polígono vs bitmap) é decisão nossa (OQ-15). |
| E-26 | Mira | Ângulo em passos de 1°; limites dependem da arma | COMMUNITY RESEARCH | MEDIUM | Sim | Os valores das tabelas são inteiros, o que é coerente com passo de 1°. |
