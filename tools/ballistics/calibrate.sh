#!/usr/bin/env bash
# Reproducible ballistic calibration. Writes tools/ballistics/reports/calibration_report.md.
# Usage: tools/ballistics/calibrate.sh [--write-metrics]
#   --write-metrics  also store the calibrated values in godot/config/game_metrics.tres
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/godot.sh"

godot="$(find_godot)"
import_project "$godot"
run_godot_script "$godot" "res://calibration/calibrate.gd" \
  "--report=$REPO_ROOT/tools/ballistics/reports/calibration_report.md" "$@"
