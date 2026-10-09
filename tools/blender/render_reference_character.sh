#!/usr/bin/env bash
# Regenerates the ORIGINAL proxy character, weapon and projectile sprites plus
# proxy_meta.json in godot/assets/characters/reference_proxy/ (docs/ART_DIRECTION_PROXY.md).
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../lib/blender.sh"
out="$here/../../godot/assets/characters/reference_proxy"

blender="$(find_blender)"
"$blender" -b --factory-startup -P "$here/create_reference_character.py" -- --out "$out" 2>&1 | grep -E "REFERENCE CHARACTER DONE|Error|Traceback|line [0-9]+" || true
test -f "$out/proxy_meta.json"
echo "Sprites written to $out"
