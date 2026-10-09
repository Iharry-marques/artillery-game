"""ORIGINAL proxy monsters for the Expedition (Milestone 5): Sprout Grunt (melee),
Pebble Slinger (artillery) and the Shell King (boss). Same cel/outline kit and
horizontal orthographic camera as the player sprites; writes enemy_meta.json with
the feet anchor and head geometry used for hitbox alignment tests.

Usage: blender -b --factory-startup -P create_reference_enemies.py -- --out <dir>
"""

import json
import math
import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import create_reference_character as kit  # noqa: E402
import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

PIXELS_PER_UNIT = kit.PIXELS_PER_UNIT
YAW = math.radians(-30.0)


def eyes(parts, center, radius, scale, yaw_left, yaw_right, pitch, size, iris_color, angry=False):
    for side, yaw in (("L", yaw_left), ("R", yaw_right)):
        y, p = math.radians(yaw), math.radians(pitch)
        direction = Vector((math.cos(p) * math.cos(y), math.cos(p) * math.sin(y), math.sin(p)))
        point = Vector(center) + Vector((direction.x * scale[0], direction.y * scale[1], direction.z * scale[2])) * radius
        frame = kit.surface_frame(direction)
        parts.append(kit.ellipsoid(f"Eye{side}", point, (0.012, size * 0.75, size), kit.flat_material("EyeWhite", kit.WHITE), rotation=frame))
        parts.append(kit.ellipsoid(f"Pupil{side}", point + direction * 0.008 + frame @ Vector((0, 0.0, -size * 0.1)), (0.01, size * 0.4, size * 0.5), kit.flat_material(f"Iris{iris_color}", iris_color), rotation=frame, outline=False))
        parts.append(kit.ellipsoid(f"Shine{side}", point + direction * 0.014 + frame @ Vector((0, -size * 0.2, size * 0.25)), (0.006, size * 0.15, size * 0.15), kit.flat_material("Shine", kit.WHITE), rotation=frame, outline=False))
        if angry:
            brow_point = point + frame @ Vector((0.0, 0.0, size * 1.05))
            tilt = Matrix.Rotation(math.radians(25 if side == "L" else -25), 3, "X")
            parts.append(kit.ellipsoid(f"Brow{side}", brow_point, (0.01, size * 0.8, size * 0.18), kit.flat_material("Brow", (0.15, 0.1, 0.1)), rotation=frame @ tilt, outline=False))


def finish_root(parts, name):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    kit.parent_all(parts, root)
    root.rotation_euler = (0.0, 0.0, YAW)
    return root


def sprout_grunt():
    """Head centre 0.42 u, radius 0.30 u (matches the content definition)."""
    parts = []
    green = kit.toon_material("GruntGreen", (0.45, 0.82, 0.35))
    leaf = kit.toon_material("GruntLeaf", (0.3, 0.68, 0.3))
    feet = kit.toon_material("GruntFeet", (0.55, 0.38, 0.25))
    center = (0.0, 0.0, 0.42)
    parts.append(kit.ellipsoid("Bulb", center, (0.3, 0.29, 0.29), green, segments=48, rings=24))
    for side, y in (("F", -0.1), ("B", 0.1)):
        parts.append(kit.ellipsoid(f"Foot{side}", (0.05, y, 0.06), (0.08, 0.055, 0.05), feet))
    for i, (yaw, length) in enumerate(((-30, 0.22), (40, 0.18), (170, 0.2))):
        direction = Vector((math.cos(math.radians(yaw)) * 0.4, math.sin(math.radians(yaw)) * 0.4, 1.0))
        parts.append(kit.cone(f"Leaf{i}", Vector((0, 0, 0.7)) + direction * 0.05, 0.06, length, leaf, direction))
    parts.append(kit.ellipsoid("Arm", (0.22, -0.18, 0.35), (0.06, 0.04, 0.05), green))
    eyes(parts, center, 0.3, (1, 1, 1), -50, -12, 6, 0.06, (0.85, 0.2, 0.15), angry=True)
    point = Vector((0.27, -0.12, 0.33))
    parts.append(kit.ellipsoid("Mouth", point, (0.008, 0.05, 0.015), kit.flat_material("Mouth", (0.35, 0.1, 0.1)), rotation=kit.surface_frame(Vector((0.85, -0.45, -0.25))), outline=False))
    return finish_root(parts, "Grunt"), {"head_center_u": [0.0, 0.42], "head_radius_u": 0.3}


def pebble_slinger():
    """Head centre 0.62 u, radius 0.30 u."""
    parts = []
    rock = kit.toon_material("Rock", (0.62, 0.6, 0.58))
    moss = kit.toon_material("Moss", (0.45, 0.75, 0.35))
    wood = kit.toon_material("Wood", (0.6, 0.42, 0.25))
    center = (0.0, 0.0, 0.62)
    parts.append(kit.ellipsoid("Head", center, (0.3, 0.29, 0.28), rock, segments=48, rings=24))
    parts.append(kit.ellipsoid("MossCap", (0.0, 0.03, 0.84), (0.2, 0.18, 0.07), moss))
    parts.append(kit.ellipsoid("Body", (0.0, 0.0, 0.25), (0.2, 0.18, 0.18), rock))
    for side, y in (("F", -0.1), ("B", 0.1)):
        parts.append(kit.ellipsoid(f"Foot{side}", (0.04, y, 0.05), (0.09, 0.06, 0.05), rock))
    parts.append(kit.cylinder("SlingStick", (0.26, -0.12, 0.45), 0.02, 0.42, wood, axis="Z"))
    parts.append(kit.ellipsoid("SlingPouch", (0.26, -0.12, 0.7), (0.06, 0.04, 0.05), wood))
    parts.append(kit.ellipsoid("Pebble", (0.26, -0.15, 0.74), (0.045, 0.04, 0.04), kit.toon_material("Pebble", (0.55, 0.42, 0.3))))
    eyes(parts, center, 0.3, (1, 1, 1), -48, -10, 2, 0.055, (0.95, 0.65, 0.1))
    return finish_root(parts, "Slinger"), {"head_center_u": [0.0, 0.62], "head_radius_u": 0.3}


def shell_king():
    """Boss: head centre 1.30 u, radius 0.72 u, about 2.2 u tall."""
    parts = []
    shell = kit.toon_material("Shell", (0.85, 0.35, 0.3))
    shell_light = kit.toon_material("ShellLight", (1.0, 0.65, 0.4))
    belly = kit.toon_material("Belly", (1.0, 0.85, 0.6))
    gold = kit.toon_material("Gold", (1.0, 0.8, 0.2))
    gem = kit.toon_material("Gem", (0.3, 0.75, 1.0))
    center = (0.0, 0.0, 1.3)
    parts.append(kit.ellipsoid("Head", center, (0.72, 0.68, 0.66), shell, segments=64, rings=32))
    parts.append(kit.ellipsoid("Face", (0.32, -0.3, 1.18), (0.36, 0.3, 0.38), belly))
    for i, z in enumerate((1.55, 1.75)):
        parts.append(kit.ellipsoid(f"Ridge{i}", (-0.15, 0.1, z), (0.5, 0.45, 0.08), shell_light))
    parts.append(kit.ellipsoid("Body", (0.0, 0.0, 0.45), (0.55, 0.5, 0.42), shell))
    for side, y in (("F", -0.3), ("B", 0.3)):
        parts.append(kit.ellipsoid(f"Leg{side}", (0.15, y, 0.12), (0.18, 0.13, 0.14), shell_light))
    claw = Matrix.Rotation(math.radians(-25), 3, "Y")
    parts.append(kit.ellipsoid("ClawArm", (0.62, -0.35, 0.75), (0.25, 0.12, 0.12), shell, rotation=claw))
    parts.append(kit.ellipsoid("ClawTop", (0.9, -0.38, 0.95), (0.2, 0.12, 0.09), shell_light))
    parts.append(kit.ellipsoid("ClawBottom", (0.88, -0.38, 0.75), (0.18, 0.11, 0.08), shell_light))
    for i, yaw in enumerate((-40, -10, 20, 50, 80)):
        direction = Vector((math.cos(math.radians(yaw)) * 0.3, math.sin(math.radians(yaw)) * 0.3, 1.0))
        parts.append(kit.cone(f"Crown{i}", Vector((0.0, 0.0, 1.9)) + Vector((direction.x, direction.y, 0)) * 0.6, 0.09, 0.3, gold, direction))
    parts.append(kit.ellipsoid("CrownBand", (0.0, 0.0, 1.88), (0.38, 0.36, 0.08), gold))
    parts.append(kit.ellipsoid("CrownGem", (0.25, -0.25, 1.9), (0.06, 0.04, 0.07), gem))
    eyes(parts, (0.15, -0.1, 1.25), 0.55, (1, 1, 1), -55, -15, 10, 0.12, (0.9, 0.15, 0.1), angry=True)
    return finish_root(parts, "King"), {"head_center_u": [0.0, 1.3], "head_radius_u": 0.72}


ENEMIES = {
    "sprout_grunt": (sprout_grunt, {"left": -0.5, "right": 0.5, "bottom": -0.05, "top": 0.95}),
    "pebble_slinger": (pebble_slinger, {"left": -0.625, "right": 0.625, "bottom": -0.08, "top": 1.17}),
    "shell_king": (shell_king, {"left": -1.3, "right": 1.3, "bottom": -0.1, "top": 2.5}),
}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = argv[argv.index("--out") + 1]
    os.makedirs(out, exist_ok=True)
    meta = {"generator": "tools/blender/create_reference_enemies.py", "pixels_per_unit": PIXELS_PER_UNIT, "enemies": {}}
    for name, (builder, frame) in ENEMIES.items():
        kit.reset_scene()
        _, head = builder()
        bpy.context.view_layer.update()
        kit.render(frame, os.path.join(out, f"{name}.png"))
        meta["enemies"][name] = {
            "size_px": list(kit.frame_size_px(frame)),
            "feet_anchor_px": kit.to_pixels(frame, 0.0, 0.0),
            **head,
        }
    with open(os.path.join(out, "enemy_meta.json"), "w") as handle:
        json.dump(meta, handle, indent=2)
    print("REFERENCE ENEMIES DONE", out)


if __name__ == "__main__":
    main()
