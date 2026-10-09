#!/usr/bin/env bash
# Regenerates ALL original proxy art: characters, weapons, projectiles, enemies and
# city buildings (docs/ART_DIRECTION_PROXY.md). Deterministic; safe to rerun.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../lib/blender.sh"
assets="$here/../../godot/assets"
blender="$(find_blender)"
run() {
  "$blender" -b --factory-startup -P "$here/$1" -- --out "$2" 2>&1 | grep -E "DONE|Error|Traceback|line [0-9]+" || true
}
run create_reference_character.py "$assets/characters/reference_proxy"
run create_reference_enemies.py "$assets/enemies"
run create_city_buildings.py "$assets/city"
test -f "$assets/characters/reference_proxy/proxy_meta.json" && test -f "$assets/enemies/enemy_meta.json" && test -f "$assets/city/game_hall.png"
echo "Proxy assets written under $assets"
