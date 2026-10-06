# Registro de decisões

Formato: contexto → decisão → consequência. Status: **ACCEPTED** (vale), **PROVISIONAL** (vale até evidência
nova), **SUPERSEDED** (substituída). Decisões novas no fim.

---

### D-001 · Idioma do projeto · ACCEPTED · 06/10/2026
- **Contexto:** desenvolvedor brasileiro; Godot/GDScript com convenções em inglês.
- **Decisão:** documentação em português brasileiro; código, identificadores, comentários de código e commits em inglês.
- **Consequência:** nenhum arquivo de código mistura idiomas.

### D-002 · Unidade de distância como constante de mundo · ACCEPTED · 06/10/2026
- **Contexto:** a régua do jogador é "1 largura de tela = 10 unidades". Se a unidade fosse derivada da largura real da
  tela, telas diferentes mudariam a física (o problema relatado nas versões widescreen).
- **Decisão:** 1 unidade de distância (u) é uma constante de mundo. O `CameraController` ajusta o zoom para que a
  largura visível seja **sempre 10 u**. O aspect ratio muda só a altura visível.
- **Consequência:** `distance_unit = visible_camera_world_width / 10` continua verdadeiro por construção. A física
  é calibrada em u e nunca lê resolução.

### D-003 · Simulação balística própria, sem motor de física do Godot · ACCEPTED · 06/10/2026
- **Contexto:** precisamos de trajetórias determinísticas e calibráveis.
- **Decisão:** a trajetória é integrada por código próprio, com passo fixo. Sem RigidBody2D para o projétil.
- **Consequência:** colisão por segmento implementada por nós; o motor do Godot pode ser usado para consultas
  de geometria, não para dinâmica.

### D-004 · Calibração no integrador real; GDScript é a fonte da verdade · ACCEPTED · 06/10/2026
- **Contexto:** a fórmula analítica e o integrador discreto divergem em O(dt). Um modelo de referência em Python poderia
  divergir silenciosamente do jogo.
- **Decisão:** constantes CALIBRATED são resolvidas rodando a `ProjectileSimulation` em GDScript (headless). Python em
  `tools/ballistics/` só para análise analítica e relatórios.
- **Consequência:** a calibração depende de o Godot estar instalado.

### D-005 · Técnicas de mira separadas da física · ACCEPTED · 06/10/2026
- **Decisão:** `AimingTechnique` são dados + preditores. Usadas por testes, Lab e eventuais dicas. Nunca mudam a trajetória.
- **Consequência:** se uma técnica não funcionar, ajusta-se a física (ou se conclui que a técnica era mal lembrada), nunca um caso especial.

### D-006 · Era de referência: DDTank clássico (Flash) · PROVISIONAL · 06/10/2026
- **Contexto:** versões posteriores mudaram números (ex.: força 95 → 100).
- **Decisão:** a referência é a memória do jogador da era clássica. Em conflito, PLAYER VERIFIED vence COMMUNITY RESEARCH.

### D-007 · Scripts do Blender em `tools/blender/` · ACCEPTED · 06/10/2026
- **Contexto:** a estrutura sugerida tinha `blender/scripts/` e `tools/blender/`, que se sobrepõem.
- **Decisão:** `blender/` guarda só arquivos-fonte `.blend`; todo script `bpy` e pipeline fica em `tools/blender/`.
  `blender/scripts/` não foi criado.

### D-008 · Sem networking e sem backend · ACCEPTED · 06/10/2026
- **Decisão:** nada de rede, servidor ou persistência online até decisão explícita do diretor de produto.

### D-009 · Modelo de vento: aceleração horizontal constante · PROVISIONAL · 06/10/2026
- **Contexto:** o modelo reproduz o ×2 do Full Throw e prevê o ×1 da técnica de 30° (PHYSICS_MODEL §4.3).
- **Decisão:** adotar como hipótese de trabalho até a calibração/validação do marco 1.

### D-010 · Parâmetros provisórios de escala · PROVISIONAL · 06/10/2026
- **Decisão:** tempo de voo do Full Throw = 4 s (define g ≈ 7,0 u/s²); dt = 1/60 s; apresentação 1 u = 100 px.
- **Consequência:** substituíveis sem tocar em gameplay, porque as relações de mira dependem só de razões (PHYSICS_MODEL §4.6).
  Recalibrar `power_scale` e `wind_accel_per_unit` ao mudar g ou dt.

### D-011 · Raiz do repositório · ACCEPTED · 06/10/2026
- **Decisão:** a raiz do repositório git é `artillery-game/`; o projeto Godot fica em `artillery-game/godot/`, isolando
  docs, pesquisa, Blender e ferramentas da importação de assets do Godot.
