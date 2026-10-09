# Direção de arte proxy (Marco 4)

Toda a arte deste marco é **proxy original**: feita para este projeto, gerada proceduralmente e substituível. Ela não é
final e não reproduz nenhum personagem, mapa, ícone ou interface do DDTank. O objetivo é ter qualidade suficiente para
julgar escala, proporção e composição jogando.

## Personagem chibi

Gerado por `tools/blender/create_reference_character.py` (Blender 4.5 LTS, headless, só primitivas). Para regerar:
`tools/blender/render_reference_character.sh`.

| Elemento | Construção |
|---|---|
| Cabeça | Esfera achatada (0,26 × 0,25 × 0,245 u) com centro a 0,72 u dos pés |
| Cabelo | Duas calotas cortadas por planos (nuca e topo), 4 mechas de franja (cones) e um tufo |
| Rosto | Olhos grandes (branco, íris na cor do time, pupila, brilho), blush e boca pequena |
| Corpo | Torso pequeno (elipsoide 0,25 × 0,30 u), cinto, pernas curtas e sapatos grandes |
| Braços | Idle: caídos ao lado. Mira: braço de trás estendido até a empunhadura |
| Arma | Lançador de 0,62 u (tubo laranja, boca amarela, aletas turquesa, mira); a mão da frente vem junto, no pivô |
| Projétil | Cápsula vermelha com faixa amarela e aletas |

**Visual:** sombreamento cel de três faixas (normal · luz fixa → rampa constante → emissão, independente de lâmpadas) e
contorno escuro por casca invertida (Solidify com normais invertidas e backface culling).

**Câmera de render:** ortográfica e **horizontal**, olhando ao longo de +Y. Alturas em u viram pixels linearmente, o que
é necessário para alinhar a cabeça desenhada com a HeadHitbox. O aspecto pseudo-3D vem de girar o corpo −35° em torno do
eixo vertical (vista 3/4); a arma é renderizada de lado, para girar em 2D sem distorção.

**Variantes:** o mesmo modelo, com materiais diferentes:
- Azul: camisa azul, cabelo castanho, íris azul, sapatos amarelos.
- Vermelho: camisa vermelha, cabelo loiro, íris âmbar, sapatos verde-água.

### Métricas de apresentação (REFERENCE PROXY / ESTIMATED)

| Métrica | Valor |
|---|---|
| Altura total (até o tufo) | 1,08 u (≈ 1,0 u sem o tufo) |
| Diâmetro visual da cabeça | 0,52 × 0,49 u (≈ 45% da altura total, ≈ 49% sem o tufo) |
| HeadHitbox | círculo de raio 0,25 u, centro 0,72 u acima dos pés |
| Pivô da arma (mão) | 0,16 u à frente, 0,27 u acima dos pés |
| Cano (pivô → ponto de lançamento) | 0,45 u |
| Resolução de render | **256 px por u** |
| Sprite do corpo | 320 × 320 px (1,25 × 1,25 u); FeetAnchor no pixel (160; 294,4) |
| Sprite da arma | 256 × 128 px (1,0 × 0,5 u); pivô no pixel (64; 64) |
| Sprite do projétil | 64 × 64 px (0,25 × 0,25 u) |

**Por que 256 px/u:** na Battle View (10 u na largura), uma janela de 1280 px mostra 128 px/u e uma de 1920 px mostra
192 px/u. Com 256 px/u o sprite sempre é **reduzido** (fica nítido) e pesa ~70 KB. Fontes maiores só gastariam memória.
O Godot escala por `100 / 256` (canvas a 100 px/u).

**Escolha das proporções e confiança:** LOW-MEDIUM. A pesquisa visual pública não trouxe referências utilizáveis (a wiki do
DDTank no Fandom responde HTTP 402; buscas só trouxeram descrições de mecânica). A escolha combina:
- a faixa sugerida (0,9–1,2 u; cabeça com 45–60% da altura);
- a pesquisa anterior (personagem com ~12–15% da altura da tela);
- convenções do gênero chibi (cabeça ≈ metade do corpo, olhos grandes, pernas curtas).

Na janela 16:9, o personagem ocupa ~19% da altura visível.

## Terreno

Shader `shaders/terrain.gdshader` sobre a máscara de colisão (uma textura com um texel por célula de 0,05 u):

- filtro linear + limiar 0,5 transformam a grade de células em contornos suaves;
- grama só onde a superfície **original** está logo acima (crateras expõem terra, não grama), com borda ondulada e
  topo claro;
- terra com gradiente de profundidade, estratos, granulação e pedrinhas;
- contorno escuro onde há célula vazia vizinha (inclusive nas bordas das crateras);
- chamuscado ao redor de cada cratera (canal azul da textura).

A textura só é regravada na região da cratera; a máscara continua sendo a única fonte de verdade.

## Fundo

Parallax manual em espaço de tela: gradiente de céu + sol (fixos), nuvens (fator 0,08, deriva lenta), montanhas com neve
(0,18) e colinas com árvores (0,38). Cores dessaturadas e azuladas para o terreno jogável ser o elemento mais saturado.

## Efeitos

Rastro com fade, sprite do projétil orientado pela velocidade, flash, bola de fogo, anel de choque, fumaça, detritos
(`CPUParticles2D`) na cor do solo/grama, números de dano saltando, flash e tremida do personagem atingido e tremor de câmera
de 0,08 u. Tudo é apresentação: nada disso altera física ou regras.

## O que é original

Tudo neste repositório: modelos, sprites, shader, fundo, HUD e mapa foram gerados por código deste projeto. Nenhuma imagem
externa foi baixada, rastreada ou usada como textura.
