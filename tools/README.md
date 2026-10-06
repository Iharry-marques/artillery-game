# tools/

Ferramentas de engenharia fora do runtime do jogo.

| Diretório | Propósito |
|---|---|
| `ballistics/` | `calibrate.sh [--write-metrics]`: roda a calibração GDScript (`godot/calibration/`) e grava `reports/calibration_report.md` (D-015). |
| `run_tests.sh` | Checagem estática de todo GDScript + suíte headless. Código ≠ 0 em qualquer falha (D-016). |
| `lib/godot.sh` | Localiza o Godot (`$GODOT`, PATH, `/Applications`, `~/Applications`) e roda scripts headless detectando erros. |
| `capture/` | Procedimentos e planilhas para medir gameplay em vídeo (tempo de voo, ápice, distâncias). Vídeos/frames ficam em `capture/raw/`, ignorado pelo git; só números são versionados. |
| `blender/` | Scripts `bpy` e pipeline de renderização/exportação, na fase de arte. Os arquivos-fonte `.blend` ficam em `../blender/` (DECISIONS D-007). |
