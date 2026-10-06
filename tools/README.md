# tools/

Ferramentas de engenharia fora do runtime do jogo.

| Diretório | Propósito |
|---|---|
| `ballistics/` | Análise e calibração do modelo balístico. A verdade é a simulação GDScript; scripts Python aqui servem só para análise analítica e geração de relatórios (DECISIONS D-004). |
| `capture/` | Procedimentos e planilhas para medir gameplay em vídeo (tempo de voo, ápice, distâncias). Vídeos/frames ficam em `capture/raw/`, ignorado pelo git; só números são versionados. |
| `blender/` | Scripts `bpy` e pipeline de renderização/exportação, na fase de arte. Os arquivos-fonte `.blend` ficam em `../blender/` (DECISIONS D-007). |
