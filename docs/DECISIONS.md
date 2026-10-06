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

### D-010 · Parâmetros provisórios de escala · PROVISIONAL · 06/10/2026 (revisada no Marco 1)
- **Decisão:** tempo de voo do Full Throw em D = 10 = 4 s (define g = 7,039396 u/s²); dt = 1/60 s; apresentação 1 u = 100 px.
- **Consequência:** substituíveis sem tocar em gameplay, porque as relações de mira dependem só de razões.
  `power_scale` e a aceleração do vento são derivados de K, ratio e g (D-014), então mudar g não exige recalibrar.
  Com o integrador exato (D-012), dt não afeta impactos.

### D-011 · Raiz do repositório · ACCEPTED · 06/10/2026
- **Decisão:** a raiz do repositório git é `artillery-game/`; o projeto Godot fica em `artillery-game/godot/`, isolando
  docs, pesquisa, Blender e ferramentas da importação de assets do Godot.

---

## Marco 1: núcleo balístico headless

### D-012 · Integrador baseline: cinemática exata para aceleração constante · ACCEPTED · 06/10/2026
- **Contexto:** o PHYSICS_MODEL do Marco 0 propunha Euler semi-implícito. Não há evidência de que o erro de integração
  histórico fizesse parte do comportamento do DDTank.
- **Decisão:** `p += v·dt + ½·a·dt²; v += a·dt`. Como a aceleração é constante no voo, a trajetória é a parábola exata e
  independe do dt. O integrador é uma estratégia (`BallisticIntegrator`), aberta a um integrador "legado" se surgir evidência.
- **Consequência:** invariância de timestep testada (≤ 1,5e-13 u). Ápice e cruzamento dentro do passo são localizados
  pelo próprio integrador.

### D-013 · Geometria de calibração sem personagem · ACCEPTED · 06/10/2026
- **Decisão:** atirador em (0, 0), alvo em (D, 0), sem offset de cano, sem hitbox, sem raio de projétil. Impacto =
  cruzamento descendente de y = 0, localizado dentro do passo.
- **Consequência:** OQ-09 deixa de bloquear o núcleo e passa a IMPORTANT (vale para a implementação visual/de gameplay).

### D-014 · Guardar relações adimensionais, derivar constantes dimensionais · ACCEPTED · 06/10/2026
- **Contexto:** as evidências restringem `K = v(95)²/g` e `a_vento/g`, não três constantes independentes.
- **Decisão:** `GameMetrics` guarda `ballistic_k`, `ballistic_k_reference_power` e `wind_accel_ratio` (CALIBRATED) e
  `gravity` (ESTIMATED). `power_scale` e a aceleração do vento são métodos derivados, nunca armazenados.
- **Consequência:** a escala de tempo pode mudar sem mexer em onde os tiros caem.

### D-015 · Calibração reproduzível dentro do projeto Godot · ACCEPTED · 06/10/2026
- **Contexto:** a calibração precisa rodar a simulação GDScript real (D-004), que só é acessível dentro de `res://`.
- **Decisão:** código de calibração em `godot/calibration/` (evidência de referência, calibrador, gerador de relatório);
  ponto de entrada em `tools/ballistics/calibrate.sh`; relatório versionado em `tools/ballistics/reports/`.
  A análise Python do Marco 0 (scratchpad) foi descartada: tudo é reproduzível pelo repositório.
- **Consequência:** `test_stored_metrics_match_a_fresh_calibration` falha se o `.tres` for editado à mão.

### D-016 · Testes headless com runner próprio e tipagem estrita · ACCEPTED · 06/10/2026
- **Decisão:** runner mínimo (`godot/tests/run_tests.gd`, base `TestCase`), sem dependência externa. `tools/run_tests.sh`
  faz checagem estática de todo `.gd` e roda a suíte. Retorna código ≠ 0 em falha de teste, erro de script ou erro de
  parse. Warnings de tipagem (`untyped_declaration`, `unsafe_*`) são **erros** no `project.godot`, porque o Godot não
  imprime warnings em `--script`/`--check-only`.
- **Consequência:** resolve OQ-18. GUT/gdUnit4 podem ser reavaliados quando houver testes de cena.

### D-017 · Métodos numéricos da calibração · ACCEPTED · 06/10/2026
- **Decisão:** ajustes de um parâmetro por mínimos quadrados com Gauss-Newton (derivada numérica); perguntas inversas
  (ângulo/força que acerta D) por Illinois (regula falsi modificada, com intervalo); ápice e cruzamento dentro do passo por
  bisseção. A métrica de erro é sempre explícita e documentada no PHYSICS_MODEL.
- **Consequência:** calibração completa em < 1 s; testes em ~8 s, incluindo a checagem estática.

### D-018 · Precisão numérica e versão do Godot · ACCEPTED · 06/10/2026
- **Decisão:** o estado da simulação usa escalares `float` (64 bits) e não `Vector2` (32 bits nos builds padrão). Vector2
  só aparece nas amostras de trajetória, que servem para exibição. Godot usado: 4.7.1-stable (official); `config/features = 4.7`.
