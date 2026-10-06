# Visão do jogo

## O que é

Um jogo de artilharia 2D original, por turnos, em que a habilidade central é **prever trajetórias**.
O jogador lê distância, desnível e vento, escolhe ângulo e força e é recompensado por dominar um
sistema balístico **determinístico e aprendível**.

## Referência técnica

O combate clássico do DDTank (era Flash) é a referência de **comportamento**. O que o tornava bom:

- trajetórias 100% previsíveis: o mesmo input sempre gera o mesmo tiro;
- uma régua mental simples (1 largura de tela = 10 unidades de distância);
- técnicas de mira humanas ("Full Throw", "30°", "65°"…) que funcionam porque a física é regular;
- vento constante durante o voo, legível no HUD, compensável por regra de bolso.

Reconstruímos as **relações matemáticas**. Não copiamos o jogo.

## O que NÃO é

- Não é clone de DDTank: sem gráficos, mapas, personagens, UI, marca, nomes ou arquivos proprietários.
- Não é simulação física realista (sem rigid body, sem arrasto aerodinâmico, sem aleatoriedade no voo).
- Não é, por enquanto, um jogo online: sem networking e sem backend até decisão explícita.
- Não é um RPG de atributos na primeira fatia vertical: dano, atraso de turno e itens começam simples.

## Pilares

1. **Previsibilidade:** a física é determinística e calibrada para que as técnicas clássicas funcionem.
2. **Legibilidade:** o jogador mede o mundo com instrumentos do HUD (minimapa, vento, ângulo, força).
3. **Independência de resolução:** a régua de 10 unidades por largura de câmera vale em qualquer tela.
4. **Apresentação separada:** a arte final (Blender) entra depois e não altera nenhuma métrica.

## Primeira fatia vertical (futuro, não implementar agora)

Dois jogadores, terreno 2D destrutível, movimento, ângulo, carga de força, vento, simulação de projétil,
explosões, dano, HP, sistema de turnos, câmera seguindo o projétil, minimapa com medição de distância e
HUD de batalha.

## Sequência de marcos

| # | Marco | Critério de saída |
|---|---|---|
| 0 | Fundação documental | Docs, evidências, hipótese física e perguntas em aberto registradas |
| 1 | Núcleo balístico headless | Simulação determinística + testes automáticos do Full Throw |
| 2 | Ballistics Lab | Ferramenta visual para configurar tiros e ver erro de impacto |
| 3 | Fatia vertical | Lista acima, com placeholders procedurais |
| 4 | Identidade e arte | Personagens, armas e cenários originais via Blender |
