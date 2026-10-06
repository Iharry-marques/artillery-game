# Perguntas em aberto

**Importância:**
- **BLOCKING:** impede o próximo marco (núcleo balístico headless).
- **IMPORTANT:** afeta a fidelidade do gameplay; precisa ser resolvida antes da fatia vertical.
- **OPTIONAL:** refinamento.

**Tipos de evidência que resolvem:** memória do jogador · medição em vídeo de gameplay · tabela da comunidade ·
experimento matemático (na nossa simulação) · pesquisa externa mais profunda · decisão de design (quando a
fidelidade histórica não importa).

Toda pergunta tem um **default proposto** para não travar o trabalho. O default é usado até a evidência chegar.

Última revisão: 06/10/2026.

---

## BLOCKING

### OQ-09 · Ponto de lançamento e ponto de referência do alvo
- **Pergunta:** de onde sai o projétil (pés, centro, cano?) e qual ponto do alvo define "distância" e "acerto"?
  Em D = 3, um offset de cano de 0,3 u já muda o resultado.
- **Default proposto:** o lançamento e a medição de distância usam o mesmo ponto de referência do personagem, na mesma
  altura do alvo (desnível 0 = mesma altura de referência). O offset do cano é zero no marco 1.
- **Resolve com:** medição em vídeo (de onde o projétil aparece) + decisão de design.

### OQ-18 · Infraestrutura de teste headless
- **Pergunta:** framework de testes (GUT, gdUnit4 ou runner próprio) e versão exata do Godot 4.x.
  Em 06/10/2026, Godot não estava instalado.
- **Default proposto:** Godot 4 estável mais recente; runner mínimo próprio (`godot --headless --script`) para os testes
  balísticos, sem dependência externa. Reavaliar GUT/gdUnit4 quando houver testes de cena.
- **Resolve com:** decisão técnica + instalação.

## IMPORTANT

### OQ-01 · Tempo de voo do Full Throw
- **Pergunta:** quantos segundos durava um Full Throw a ~10 de distância? Define a gravidade (o *feel*).
- **Default:** 4 s (D-010).
- **Resolve com:** memória do jogador (ordem de grandeza) ou cronometragem em vídeo.

### OQ-02 · Altura do ápice do Full Throw
- **Pergunta:** o projétil do Full Throw subia ≈ 14 u (≈ 1,4 largura de tela) acima do atirador, como o modelo prevê?
- **Resolve com:** vídeo (tempo fora da tela no topo + câmera seguindo) ou memória ("sumia da tela por quanto tempo?").
  Se o ápice real for muito diferente, o modelo sem arrasto está errado.

### OQ-04 · Magnitude da tabela de força de 30°
- **Pergunta:** a tabela D1 → 14, D5 → 32, D10 → 47,5 é real? O modelo calibrado no Full Throw prevê ~19 / 42 / 60.
- **Resolve com:** memória do jogador (lembra alguma força de técnica de ângulo baixo?) ou tabela da comunidade com fonte verificável.
- **Default:** confiar no Full Throw; tratar a tabela como LOW.

### OQ-05 · Fator de vento das técnicas de 65° e 50°
- **Pergunta:** a comunidade diz ×2 para ambas; o modelo prevê ≈ 2,56 (65°) e ≈ 6,8 (50°).
- **Resolve com:** memória do jogador / tabela da comunidade; experimento na simulação após o marco 1.
  Hipótese: a técnica de 50° compensava o vento pela **força**, não pelo ângulo.

### OQ-06 · Half Throw
- **Pergunta:** força e regra exatas. Fonte: força ≈ 60 e 90 − 2D; o modelo exige força ≈ 67 para 90 − 2D.
- **Resolve com:** memória do jogador; tabela da comunidade.

### OQ-07 · Full Throw além de 10 unidades
- **Pergunta:** a regra 90 − D funcionava em D = 15, 20? O modelo prevê que o tiro cai curto (14,5 / 18,7).
  Jogadores usavam correções para distâncias longas?
- **Resolve com:** memória do jogador; vídeo.

### OQ-08 · Vento: faixa, passo e geração
- **Pergunta:** faixa (0–5?), passo (0,1?), como muda entre turnos, se há turnos sem vento.
- **Default:** −5,0 a +5,0, passo 0,1, passeio aleatório com seed determinística.
- **Resolve com:** memória do jogador; vídeo.

### OQ-10 · Barra de força
- **Pergunta:** tempo de carga 0 → 100, comportamento ao passar de 100 (trava? volta a 0? oscila?).
- **Default:** linear, 0 → 100 em 2,5 s; ao estourar, volta a 0 (fonte COMMUNITY).
- **Resolve com:** memória do jogador; vídeo.

### OQ-11 · Limites de ângulo por arma
- **Pergunta:** quais faixas existiam? A fonte cita 20–65 / 55–75 / 10–40, mas o Full Throw exige até ~87.
  **Contradição:** se a arma canônica ia só até 65°, como funcionava o Full Throw a 80–87°?
  Hipóteses: limites da fonte errados; limites de outra versão; o Full Throw era feito com outra arma.
- **Default:** arma de teste com 0–90°.
- **Resolve com:** memória do jogador.

### OQ-12 · Hitbox do personagem
- **Pergunta:** largura e altura em u. A fonte estima ~0,45 × 0,75 u (LOW).
- **Resolve com:** medição em vídeo relativa à largura da tela.

### OQ-13 · Explosão, cratera e dano
- **Pergunta:** raio de dano, raio de cratera, curva de decaimento, dano base.
- **Resolve com:** vídeo + decisão de design (fidelidade baixa aceitável).

### OQ-14 · Ordem de turno
- **Pergunta:** alternância simples ou fila por atraso (delay)? A fonte se contradiz nos números.
- **Default para a fatia vertical:** alternância simples entre 2 jogadores; delay fica para depois.
- **Resolve com:** memória do jogador + decisão de produto.

### OQ-15 · Representação do terreno
- **Pergunta:** polígonos (`Geometry2D.clip_polygons`) ou máscara de bitmap?
- **Resolve com:** experimento técnico (desempenho, precisão da colisão por segmento) no marco do terreno.

### OQ-20 · Compensação de desnível vertical
- **Pergunta:** como os jogadores corrigiam o desnível no Full Throw (regra de bolso, tipo "+1 de distância por X de altura")?
- **Resolve com:** memória do jogador; depois, previsão pela nossa simulação para comparar.

## OPTIONAL

### OQ-03 · Aspect ratio da área de jogo clássica
- **Pergunta:** 800×600 (4:3) ou 1000×600 (5:3)? Afeta só a altura visível (7,5 u vs 6 u).
- **Default:** decidir pela apresentação; 16:9 (5,625 u de altura) é aceitável.
- **Resolve com:** pesquisa externa.

### OQ-16 · Movimento
- **Pergunta:** velocidade, stamina por turno, inclinação máxima (~45° segundo a fonte), ausência de pulo.
- **Resolve com:** vídeo + decisão de design.

### OQ-17 · Mapa
- **Pergunta:** largura (25–40 u segundo a fonte), altura, limite de morte por queda.
- **Resolve com:** decisão de design.

### OQ-19 · Git LFS para arquivos binários
- **Pergunta:** usar Git LFS para `.blend` e renders?
- **Resolve com:** decisão técnica antes do primeiro asset binário.

### OQ-21 · Técnica de 20°
- **Pergunta:** força/regra. Sem dados. O modelo prevê fator de vento ≈ 0,31.
- **Resolve com:** memória do jogador; tabela da comunidade.
