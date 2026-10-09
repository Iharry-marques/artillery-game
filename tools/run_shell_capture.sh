#!/usr/bin/env bash
# Visual review of the product shell: walks the main screens, plays a PvP duel and a
# PvE expedition (AI on both sides), saves screenshots to <absolute dir> and quits.
#   tools/run_shell_capture.sh /absolute/dir
# Uses a throwaway save (user://capture_save.json); the player's save is untouched.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/godot.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 /absolute/output/dir" >&2
  exit 2
fi
godot="$(find_godot)"
import_project "$godot"
"$godot" --path "$GODOT_PROJECT" res://scenes/debug/shell_capture.tscn -- "--shell-capture=$1"
