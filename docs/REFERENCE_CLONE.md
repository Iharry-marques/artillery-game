# Battle Reference Clone (Marco 4)

Cena de batalha temporária, com **composição e sensação** próximas do combate clássico do DDTank, para que escala,
proporções e enquadramento possam ser julgados jogando. É o Combat Sandbox do Marco 3 com apresentação nova; regras e
balística são as mesmas.

```bash
export GODOT=~/Downloads/Godot.app/Contents/MacOS/Godot   # se necessário
tools/run_combat_sandbox.sh                               # jogar (também F5 no editor)
tools/run_combat_sandbox.sh --capture=/dir/absoluto       # partida roteirizada + screenshots
tools/blender/render_reference_character.sh               # regerar sprites do personagem
```

## O que imita de propósito a gramática visual clássica

| Elemento | Como aparece aqui |
|---|---|
| Personagens chibi | Cabeça enorme (~metade do corpo), corpo pequeno, pernas curtas, olhos grandes, arma desproporcional |
| Leitura da cabeça como alvo | A HeadHitbox coincide com a cabeça desenhada (testado); F2 mostra as duas |
| Escala da tela | Battle View de 10 u; personagem com ~1 u, ~19% da altura visível em 16:9 |
| Terreno | Grama no topo, terra marrom texturizada, contorno escuro, crateras com borda escura |
| Fundo | Céu claro, nuvens, montanhas distantes, parallax |
| HUD | Vento no topo central; HP/identidade no topo esquerdo; minimapa no topo direito; ângulo embaixo à esquerda; **barra de força grande** embaixo no centro; status embaixo à direita |
| Minimapa | Instrumento: silhueta, jogadores e retângulo da câmera = régua de 10 u com 10 divisões |
| Fluxo de câmera | Enquadra o jogador; segue o projétil (até para fora da tela por cima); para no impacto; volta suavemente |
| Feedback | Explosão, detritos, número de dano, flash no atingido, banner de turno |

## O que NÃO foi copiado

Nenhum sprite, personagem, mapa, textura, ícone, logo, nome, áudio ou arquivo do DDTank. Nenhuma imagem de referência foi
baixada ou rastreada. Arte, HUD, fundo e mapa são procedurais e originais (ver ART_DIRECTION_PROXY.md).

## Jogo calibrado × apresentação

| Calibrado / regra de jogo (inalterado) | Apresentação (novo, proxy) |
|---|---|
| `ProjectileSimulation`, K = 29,033036 u, razão do vento 0,034401 | Sprites do personagem, arma e projétil |
| Colisão com terreno, cabeça e limites | Shader do terreno, fundo, parallax |
| Turnos, dano, cratera, queda, vento | Efeitos, tremor de câmera, banner, HUD, minimapa |

Mudaram só placeholders de gameplay em `combat_rules.tres` (valores ESTIMATED):
- centro da cabeça 0,65 → **0,72 u**, para casar com a arte;
- ponto de lançamento passou de um offset fixo para a **ponta do cano** (pivô 0,16/0,27 u + cano 0,45 u na direção da
  mira);
- o mapa de teste deu lugar ao `ReferenceBattleMap`;
- suavização e tremor de câmera ganharam valores próprios.

## Revisão visual feita (screenshots do `--capture`)

Problemas encontrados e corrigidos antes da entrega:

1. **Contorno do personagem ausente:** a espessura do Solidify estava em coordenadas locais de esferas unitárias
   escaladas. Corrigido aplicando a escala antes do modificador.
2. **Fundo quebrado:** um véu verde-azulado cobria o céu e as montanhas apareciam invertidas no topo, porque a convenção de
   offset do `Parallax2D` não era a assumida. Trocado por parallax manual em espaço de tela.
3. **Câmera atrasada no voo:** na descida o projétil chegava à borda inferior, atrás do HUD. Adicionada zona morta
   (margens 25% / 18% / 34%).
4. **HUD:** texto de ajuda cortado, status do turno invisível, seta do vento sobre o número e banner cobrindo a cabeça.
   A barra inferior foi refeita com containers e o banner subiu.
5. **Arma tapando o rosto a 80°:** pivô movido para 0,16 u à frente e 0,27 u acima.
6. **Pedrinhas do terreno** viravam manchas grandes: menores e mais raras.
7. **Shader:** `TEXTURE` não pode ser passado a função auxiliar; amostragem movida para o `fragment()`.

Resultado da última captura: o Full Throw carregado na barra (força 95,33, 80°, vento 0) **acertou a cabeça** do oponente
(−35). O revide com o Full Throw automático também acertou; a partida terminou em GAME_OVER e o reset voltou ao estado
inicial exato.

## O que julgar jogando

1. Tamanho do personagem e da cabeça em relação à tela de 10 u (F2 mostra a hitbox real sobre a arte).
2. Se a hitbox da cabeça parece grande ou pequena demais ao acertar e errar.
3. Leitura da arma e do ângulo: lançador girando, mostrador do ângulo.
4. Tempo de carga da barra de força (2,5 s de 0 a 100).
5. Duração do voo (~4 s no Full Throw; gravidade provisória).
6. Densidade visual: o terreno compete com o personagem? O fundo distrai?
7. Composição do HUD e do minimapa: dá para ler ângulo, força, vento, HP e turno de relance?
8. Câmera: suavidade, zona morta no voo, tempo parado no impacto.
