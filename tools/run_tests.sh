#!/usr/bin/env bash
# Static check of every GDScript file, then the headless test suite.
# Exit status is non-zero on any failure. Usage: tools/run_tests.sh [--filter=<text>]
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/godot.sh"

godot="$(find_godot)"
import_project "$godot"
check_scripts "$godot"
echo "Static check passed."
run_godot_script "$godot" "res://tests/run_tests.gd" "$@"
