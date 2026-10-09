#!/usr/bin/env bash
# Resolves the Blender executable: $BLENDER, then PATH, then standard macOS app locations.

find_blender() {
  if [[ -n "${BLENDER:-}" ]]; then
    echo "$BLENDER"
    return 0
  fi
  if command -v blender >/dev/null 2>&1; then
    command -v blender
    return 0
  fi
  local candidate
  for candidate in "/Applications/Blender.app" "$HOME/Applications/Blender.app"; do
    if [[ -x "$candidate/Contents/MacOS/Blender" ]]; then
      echo "$candidate/Contents/MacOS/Blender"
      return 0
    fi
  done
  echo "Blender not found. Set BLENDER=/path/to/Blender or add it to PATH." >&2
  return 1
}
