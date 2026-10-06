# research/

Material de pesquisa externo. **Tudo aqui é hipótese**, até ser confirmado por memória de jogador,
medição ou calibração. Nada deste diretório é dependência de runtime.

Regras:

- Não salvar imagens, sprites, screenshots ou vídeos de jogos de terceiros (ver `.gitignore`).
- Registrar links e citações como texto, com a data de consulta.
- Números extraídos daqui entram em [../docs/GAME_METRICS.md](../docs/GAME_METRICS.md) como ESTIMATED / LOW, nunca como CONFIRMED.

## Avaliação de `DDTANK_DEEP_RESEARCH.md` (06/10/2026)

**Confiabilidade geral: BAIXA a MÉDIA.** Útil como mapa de temas e como fonte de hipóteses
testáveis. **Não** serve como fonte de constantes.

Motivos:

1. **Não cita fontes verificáveis.** A seção "Sources" menciona Baidu Tieba, 4399 e Bilibili de forma
   genérica, sem links, autores ou datas.
2. **Rótulos de confiança sem lastro.** Ex.: "1000 px de largura [MEASURED]" sem descrever a medição;
   "Gravidade ≈ 450 px/s² [ESTIMATED]" e "12.5 px/s por ponto de força" sem derivação.
3. **Contradições internas:**
   - Diz que "ΔÂngulo = Vento × 2" é a "lei universal", mas a própria técnica de 30° descrita usa `30 ± Vento` (fator 1).
   - Resolução clássica citada ora como 800×600 (seção 2), ora como 1000×600 (seção 22).
   - Atraso de turno: "passar ≈ +20, atirar ≈ +10" na seção 14; "passar +200 ms, atirar +100 ms" na seção 22.
     Unidades diferentes, e passar a vez custando mais que atirar é contraintuitivo.
4. **Linguagem com sinais de geração automática** (pt-PT misturado, frases enfáticas sem conteúdo,
   termos como "estratosférica"), o que exige verificar cada afirmação.

O que ele traz de útil, com a validação feita em [../docs/PHYSICS_MODEL.md](../docs/PHYSICS_MODEL.md):

- Exemplo de vento no high throw com sinal consistente com a física e com a memória do jogador
  (vento a favor → aumentar ângulo; vento contra → diminuir).
- Tabela de força da técnica de 30° (1 → 14, 5 → 32, 10 → 47,5) cujo **formato** é compatível com
  velocidade linear na força e alcance ∝ força². A **magnitude** não bate com a calibração do high throw (ver OQ-04).
- Fator de vento 1 para a técnica de 30°, que o modelo candidato **prevê** de forma independente (ver PHYSICS_MODEL §5).
- Hipóteses de arquitetura: terreno por subtração de polígonos, ordem de turno por atraso (delay), queda no vazio.
