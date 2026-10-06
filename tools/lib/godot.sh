#!/usr/bin/env bash
# Shared helpers for repository scripts that drive the Godot project headlessly.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT_PROJECT="$REPO_ROOT/godot"

# Prints the Godot 4 executable: $GODOT, then PATH, then standard macOS app locations.
find_godot() {
  if [[ -n "${GODOT:-}" ]]; then
    echo "$GODOT"
    return 0
  fi
  local candidate
  for candidate in godot godot4; do
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
  done
  for candidate in "/Applications/Godot.app" "$HOME/Applications/Godot.app"; do
    if [[ -x "$candidate/Contents/MacOS/Godot" ]]; then
      echo "$candidate/Contents/MacOS/Godot"
      return 0
    fi
  done
  echo "Godot 4 not found. Set GODOT=/path/to/Godot or add it to PATH." >&2
  return 1
}

# Imports the project so global script classes are registered before running scripts.
import_project() {
  "$1" --headless --path "$GODOT_PROJECT" --import >/dev/null 2>&1
}

# Runs a SceneTree script; fails if Godot exits non-zero or reports any script error.
run_godot_script() {
  local godot="$1" script="$2"
  shift 2
  local log status
  log="$(mktemp)"
  set +e
  "$godot" --headless --path "$GODOT_PROJECT" --script "$script" -- "$@" 2>&1 | tee "$log"
  status="${PIPESTATUS[0]}"
  set -e
  if grep -qE "SCRIPT ERROR|Parse Error|^ERROR:|WARNING: .*GDScript" "$log"; then
    echo "Godot reported errors or warnings (see output above)." >&2
    status=1
  fi
  rm -f "$log"
  return "$status"
}

# Parses every GDScript file. GDScript warnings are configured as errors in
# project.godot, so this is the project's static type check.
check_scripts() {
  local godot="$1" file output failed=0
  while IFS= read -r file; do
    output="$("$godot" --headless --path "$GODOT_PROJECT" --check-only --script "res://$file" 2>&1 | grep -E "ERROR|Parse Error|WARNING" || true)"
    if [[ -n "$output" ]]; then
      echo "Static check failed: $file" >&2
      echo "$output" >&2
      failed=1
    fi
  done < <(cd "$GODOT_PROJECT" && find . -name '*.gd' -not -path './.godot/*' | sed 's|^\./||' | sort)
  return "$failed"
}
