#!/usr/bin/env bash
# Opens the game (boot screen -> character -> city -> ...). Progress is saved to
# user://reference_clone_save.json; "Reset profile" on the boot screen deletes it.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/godot.sh"

godot="$(find_godot)"
import_project "$godot"
"$godot" --path "$GODOT_PROJECT" "$@"
