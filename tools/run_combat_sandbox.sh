#!/usr/bin/env bash
# Opens the playable combat sandbox. Extra arguments become Godot user args, e.g.
#   tools/run_combat_sandbox.sh --capture=/absolute/dir   (scripted playthrough + screenshots, then quit)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/godot.sh"

godot="$(find_godot)"
import_project "$godot"
user_args=()
if [[ $# -gt 0 ]]; then
  user_args=(-- "$@")
fi
"$godot" --path "$GODOT_PROJECT" res://scenes/gameplay/combat_sandbox.tscn ${user_args[@]+"${user_args[@]}"}
