"""ORIGINAL proxy buildings for the City hub (Milestone 5): Game Hall, Blacksmith,
Shop, Expedition Pier, Guild, Post Office and Hall of Fame. Toy-like primitives
with the same cel/outline kit, rendered from an elevated 3/4 orthographic view.

Usage: blender -b --factory-startup -P create_city_buildings.py -- --out <dir>
"""

import math
import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import create_reference_character as kit  # noqa: E402
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

PIXELS_PER_UNIT = 128
FRAME = 3.2


def box(name, center, size, material, outline=True):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = obj.modifiers.new("Bevel", "BEVEL")
    bevel.width = min(size) * 0.12
    bevel.segments = 3
    return kit.finish(obj, material, outline)


def roof(name, center, radius, height, material, vertices=4):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=0.0, depth=height, location=center, rotation=(0, 0, math.pi / vertices))
    obj = bpy.context.active_object
    obj.name = name
    return kit.finish(obj, material, True)


def game_hall():
    m = kit.toon_material
    box("Base", (0, 0, 0.45), (2.2, 1.6, 0.9), m("HallWall", (0.98, 0.92, 0.8)))
    kit.cylinder("Drum", (0, 0, 1.15), 0.95, 0.6, m("HallRed", (0.9, 0.3, 0.3)), axis="Z", vertices=48)
    kit.ellipsoid("Dome", (0, 0, 1.45), (0.95, 0.95, 0.75), m("HallDome", (1.0, 0.75, 0.25)), segments=48, rings=24)
    box("Door", (0, -0.82, 0.38), (0.6, 0.08, 0.7), m("HallDoor", (0.45, 0.25, 0.2)))
    for x in (-0.9, 0.9):
        kit.cylinder(f"Pole{x}", (x, -0.6, 1.4), 0.03, 1.2, m("Pole", (0.4, 0.35, 0.35)), axis="Z")
        box(f"Flag{x}", (x + 0.18, -0.6, 1.85), (0.34, 0.03, 0.22), m("Flag", (0.3, 0.6, 1.0) if x < 0 else (1.0, 0.35, 0.35)))
    kit.ellipsoid("Star", (0, -0.62, 1.15), (0.14, 0.05, 0.14), m("Star", (1.0, 0.9, 0.3)))


def blacksmith():
    m = kit.toon_material
    box("House", (0, 0, 0.6), (1.6, 1.3, 1.2), m("Stone", (0.7, 0.66, 0.62)))
    roof("Roof", (0, 0, 1.55), 1.2, 0.8, m("SmithRoof", (0.45, 0.32, 0.55)))
    box("Chimney", (0.5, 0.3, 1.7), (0.3, 0.3, 0.8), m("Brick", (0.75, 0.38, 0.3)))
    for i, z in enumerate((2.25, 2.55, 2.8)):
        kit.ellipsoid(f"Smoke{i}", (0.55 + i * 0.12, 0.3, z), (0.16 + i * 0.04,) * 3, m("Smoke", (0.85, 0.85, 0.88)), outline=False)
    box("Forge", (0, -0.68, 0.38), (0.6, 0.06, 0.6), kit.flat_material("ForgeGlow", (1.0, 0.55, 0.15)))
    box("AnvilBase", (-0.75, -0.75, 0.15), (0.2, 0.2, 0.3), m("Iron", (0.3, 0.32, 0.38)))
    box("AnvilTop", (-0.75, -0.75, 0.36), (0.45, 0.2, 0.14), m("Iron", (0.3, 0.32, 0.38)))
    box("Sign", (0.62, -0.7, 0.95), (0.42, 0.05, 0.3), m("SignWood", (0.75, 0.55, 0.3)))
    kit.ellipsoid("Hammer", (0.62, -0.76, 0.95), (0.12, 0.02, 0.06), m("Iron", (0.3, 0.32, 0.38)), outline=False)


def shop():
    m = kit.toon_material
    box("Counter", (0, 0, 0.4), (1.8, 1.1, 0.8), m("ShopWood", (0.85, 0.62, 0.38)))
    for i in range(6):
        color = (1.0, 0.35, 0.35) if i % 2 == 0 else (1.0, 0.96, 0.9)
        box(f"Stripe{i}", (-0.75 + i * 0.3, -0.25, 1.35), (0.3, 1.5, 0.12), m(f"Awning{i % 2}", color))
    for x in (-0.85, 0.85):
        kit.cylinder(f"Post{x}", (x, -0.95, 0.85), 0.04, 1.0, m("Post", (0.6, 0.42, 0.25)), axis="Z")
    for i, (x, color) in enumerate(((-0.5, (0.4, 0.8, 1.0)), (0.0, (1.0, 0.8, 0.25)), (0.5, (0.55, 0.9, 0.45)))):
        kit.ellipsoid(f"Goods{i}", (x, -0.55, 0.92), (0.16, 0.14, 0.14), m(f"Goods{i}", color))
    kit.cylinder("Coins", (0.75, -0.75, 0.88), 0.14, 0.12, m("Coins", (1.0, 0.85, 0.2)), axis="Z")


def expedition():
    m = kit.toon_material
    box("Pier", (0, 0, 0.18), (2.4, 1.2, 0.2), m("Planks", (0.7, 0.5, 0.3)))
    for x in (-1.0, -0.3, 0.4, 1.1):
        kit.cylinder(f"Pile{x}", (x, -0.55, 0.0), 0.06, 0.5, m("Pile", (0.5, 0.35, 0.22)), axis="Z")
    kit.cylinder("Tower", (-0.75, 0.2, 1.0), 0.32, 1.5, m("Lighthouse", (0.98, 0.95, 0.92)), axis="Z")
    kit.cylinder("TowerBand", (-0.75, 0.2, 1.1), 0.335, 0.25, m("LightBand", (0.9, 0.3, 0.3)), axis="Z")
    kit.ellipsoid("Lamp", (-0.75, 0.2, 1.85), (0.22, 0.22, 0.2), kit.flat_material("Lamp", (1.0, 0.92, 0.5)))
    roof("LampRoof", (-0.75, 0.2, 2.1), 0.3, 0.3, m("LampRoof", (0.3, 0.45, 0.8)), vertices=16)
    kit.ellipsoid("Boat", (0.6, -0.6, 0.35), (0.6, 0.25, 0.16), m("Boat", (0.3, 0.55, 0.9)))
    kit.cylinder("Mast", (0.6, -0.6, 0.85), 0.03, 0.9, m("Pole", (0.4, 0.35, 0.35)), axis="Z")
    box("Sail", (0.75, -0.6, 0.95), (0.3, 0.02, 0.5), m("Sail", (1.0, 0.98, 0.9)))


def guild():
    m = kit.toon_material
    box("Keep", (0, 0, 0.7), (1.4, 1.2, 1.4), m("GuildStone", (0.62, 0.66, 0.78)))
    for x in (-0.7, 0.7):
        kit.cylinder(f"Tower{x}", (x, -0.4, 0.9), 0.3, 1.8, m("GuildStone", (0.62, 0.66, 0.78)), axis="Z", vertices=24)
        roof(f"TowerRoof{x}", (x, -0.4, 2.0), 0.36, 0.5, m("GuildRoof", (0.3, 0.4, 0.85)), vertices=16)
    box("Gate", (0, -0.62, 0.4), (0.45, 0.06, 0.65), m("Gate", (0.4, 0.25, 0.2)))
    box("Banner", (0, -0.63, 1.1), (0.35, 0.03, 0.5), m("Banner", (0.95, 0.75, 0.2)))


def mail():
    m = kit.toon_material
    box("Post", (0, 0, 0.5), (1.3, 1.0, 1.0), m("MailWall", (1.0, 0.95, 0.85)))
    roof("Roof", (0, 0, 1.25), 0.95, 0.55, m("MailRoof", (0.35, 0.65, 0.95)))
    kit.cylinder("Box", (0.85, -0.5, 0.45), 0.2, 0.7, m("MailBox", (0.95, 0.3, 0.3)), axis="Z")
    kit.ellipsoid("BoxTop", (0.85, -0.5, 0.8), (0.2, 0.2, 0.12), m("MailBox", (0.95, 0.3, 0.3)))
    box("Envelope", (0, -0.53, 0.75), (0.45, 0.04, 0.3), m("Envelope", (1.0, 1.0, 0.95)))
    box("Seal", (0, -0.56, 0.75), (0.1, 0.02, 0.1), m("Seal", (0.95, 0.3, 0.3)), outline=False)


def ranking():
    m = kit.toon_material
    for i, (x, h) in enumerate(((-0.6, 0.4), (0.0, 0.7), (0.6, 0.25))):
        box(f"Step{i}", (x, 0, h / 2), (0.6, 0.6, h), m(f"Podium{i}", ((0.85, 0.85, 0.9), (1.0, 0.8, 0.25), (0.85, 0.55, 0.35))[i]))
    kit.cylinder("TrophyStem", (0.0, 0, 0.95), 0.05, 0.3, m("Gold", (1.0, 0.8, 0.2)), axis="Z")
    kit.ellipsoid("TrophyCup", (0.0, 0, 1.25), (0.25, 0.25, 0.25), m("Gold", (1.0, 0.8, 0.2)))
    for x in (-0.27, 0.27):
        kit.ellipsoid(f"Handle{x}", (x, 0, 1.28), (0.08, 0.03, 0.1), m("Gold", (1.0, 0.8, 0.2)))
    kit.ellipsoid("Star", (0.0, -0.2, 1.3), (0.08, 0.02, 0.08), kit.flat_material("StarGlow", (1.0, 1.0, 0.85)), outline=False)


BUILDINGS = {
    "game_hall": game_hall, "blacksmith": blacksmith, "shop": shop, "expedition": expedition,
    "guild": guild, "mail": mail, "ranking": ranking,
}


def render_building(path):
    scene = bpy.context.scene
    size = round(FRAME * PIXELS_PER_UNIT)
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    camera_data = bpy.data.cameras.new("Camera")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = FRAME
    camera = bpy.data.objects.new("Camera", camera_data)
    scene.collection.objects.link(camera)
    pitch = math.radians(28.0)
    yaw = math.radians(-24.0)
    direction = Vector((math.sin(yaw) * math.cos(pitch), -math.cos(yaw) * math.cos(pitch), math.sin(pitch)))
    target = Vector((0.0, 0.0, 1.0))
    camera.location = target + direction * 10.0
    camera.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = argv[argv.index("--out") + 1]
    os.makedirs(out, exist_ok=True)
    for name, builder in BUILDINGS.items():
        kit.reset_scene()
        builder()
        render_building(os.path.join(out, f"{name}.png"))
    print("CITY BUILDINGS DONE", out)


if __name__ == "__main__":
    main()
