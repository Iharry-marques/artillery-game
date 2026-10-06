#!/usr/bin/env bash
# Opens the Ballistics Lab in a window. Extra arguments become Godot user args, e.g.
#   tools/run_ballistics_lab.sh --capture=/absolute/dir   (screenshots of every scenario, then quit)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/godot.sh"

godot="$(find_godot)"
import_project "$godot"
user_args=()
if [[ $# -gt 0 ]]; then
  user_args=(-- "$@")
fi
"$godot" --path "$GODOT_PROJECT" res://scenes/debug/ballistics_lab.tscn ${user_args[@]+"${user_args[@]}"}
