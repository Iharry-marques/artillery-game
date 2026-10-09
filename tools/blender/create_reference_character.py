"""Procedural ORIGINAL chibi proxy character for the battle reference clone (Milestone 4).

Builds a big-headed character, an oversized launcher and a projectile from Blender
primitives, renders them as transparent sprites with an orthographic camera and
writes the metadata the game needs (pixels per unit, anchors, head geometry).

Run through tools/blender/render_reference_character.sh. Blender units = game
units (u). The camera is horizontal and orthographic, so heights in u map
linearly to sprite pixels (needed to align the head art with the HeadHitbox).

Usage: blender -b --factory-startup -P create_reference_character.py -- --out <dir>
"""

import json
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

# --- Presentation metrics (REFERENCE PROXY / ESTIMATED, docs/ART_DIRECTION_PROXY.md) ---

PIXELS_PER_UNIT = 256
# Body sprite frame in u: x in [-0.625, 0.625], z in [-0.10, 1.15] -> 320 x 320 px.
BODY_FRAME = {"left": -0.625, "right": 0.625, "bottom": -0.10, "top": 1.15}
# Weapon sprite frame in u (barrel along +x, pivot at the origin) -> 256 x 128 px.
WEAPON_FRAME = {"left": -0.25, "right": 0.75, "bottom": -0.25, "top": 0.25}
# Projectile sprite frame in u (nose along +x) -> 64 x 64 px.
PROJECTILE_FRAME = {"left": -0.125, "right": 0.125, "bottom": -0.125, "top": 0.125}

HEAD_CENTER_Z = 0.72
HEAD_RADIUS = 0.26
HEAD_SCALE = (1.0, 0.96, 0.94)
# Hand / weapon pivot, relative to the feet, in the facing direction.
# Low and forward so a steep launcher does not cover the face.
WEAPON_PIVOT = (0.16, 0.27)
BARREL_LENGTH = 0.45
# How much the body turns towards the camera (3/4 view), degrees.
BODY_YAW_DEGREES = -35.0
OUTLINE_THICKNESS = 0.012

LIGHT_DIRECTION = Vector((-0.45, -0.6, 0.66)).normalized()
OUTLINE_COLOR = (0.13, 0.09, 0.12)
SKIN = (1.0, 0.84, 0.72)
WHITE = (0.98, 0.98, 1.0)
DARK = (0.08, 0.07, 0.12)

VARIANTS = {
    "blue": {"shirt": (0.18, 0.52, 0.98), "hair": (0.33, 0.2, 0.12), "iris": (0.1, 0.55, 0.95), "pants": (0.2, 0.24, 0.42), "shoes": (0.98, 0.83, 0.25)},
    "red": {"shirt": (0.95, 0.28, 0.3), "hair": (0.98, 0.72, 0.28), "iris": (0.85, 0.35, 0.15), "pants": (0.35, 0.2, 0.25), "shoes": (0.35, 0.85, 0.75)},
}
WEAPON_COLORS = {"tube": (1.0, 0.58, 0.16), "ring": (1.0, 0.86, 0.22), "dark": (0.22, 0.22, 0.32), "fin": (0.2, 0.78, 0.75)}
PROJECTILE_COLORS = {"body": (0.95, 0.3, 0.25), "band": (1.0, 0.85, 0.2), "fin": (0.25, 0.25, 0.35)}

_materials = {}


# --- Scene and materials -----------------------------------------------------------


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.eevee.taa_render_samples = 16
    _materials.clear()


def toon_material(name, rgb):
    """Light-independent cel shading: normal . light -> 3-step ramp -> emission."""
    key = (name, tuple(rgb))
    if key in _materials:
        return _materials[key]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    geometry = nodes.new("ShaderNodeNewGeometry")
    dot = nodes.new("ShaderNodeVectorMath")
    dot.operation = "DOT_PRODUCT"
    dot.inputs[1].default_value = LIGHT_DIRECTION
    remap = nodes.new("ShaderNodeMath")
    remap.operation = "MULTIPLY_ADD"
    remap.inputs[1].default_value = 0.5
    remap.inputs[2].default_value = 0.5
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    shadow = tuple(c * 0.68 for c in rgb)
    highlight = tuple(min(1.0, c * 1.12 + 0.06) for c in rgb)
    elements = ramp.color_ramp.elements
    elements[0].position = 0.0
    elements[0].color = (*shadow, 1.0)
    elements[1].position = 0.42
    elements[1].color = (*rgb, 1.0)
    top = elements.new(0.9)
    top.color = (*highlight, 1.0)
    emission = nodes.new("ShaderNodeEmission")
    output = nodes.new("ShaderNodeOutputMaterial")
    links.new(geometry.outputs["Normal"], dot.inputs[0])
    links.new(dot.outputs["Value"], remap.inputs[0])
    links.new(remap.outputs["Value"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], emission.inputs["Color"])
    links.new(emission.outputs["Emission"], output.inputs["Surface"])
    _materials[key] = mat
    return mat


def flat_material(name, rgb):
    key = ("flat", name, tuple(rgb))
    if key in _materials:
        return _materials[key]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs["Color"].default_value = (*rgb, 1.0)
    output = nodes.new("ShaderNodeOutputMaterial")
    mat.node_tree.links.new(emission.outputs["Emission"], output.inputs["Surface"])
    _materials[key] = mat
    return mat


def outline_material():
    mat = flat_material("Outline", OUTLINE_COLOR)
    mat.use_backface_culling = True
    return mat


def finish(obj, material, outline=True):
    obj.data.materials.append(material)
    if hasattr(obj.data, "shade_smooth"):
        obj.data.shade_smooth()
    if outline:
        obj.data.materials.append(outline_material())
        mod = obj.modifiers.new("Outline", "SOLIDIFY")
        mod.thickness = OUTLINE_THICKNESS
        mod.offset = 1.0
        mod.use_flip_normals = True
        mod.use_rim = False
        mod.material_offset = 1
    return obj


# --- Primitive helpers ----------------------------------------------------------------


def ellipsoid(name, center, radii, material, rotation=None, outline=True, segments=40, rings=20):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1.0, location=center)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = radii
    if rotation is not None:
        obj.rotation_mode = "QUATERNION"
        obj.rotation_quaternion = rotation.to_quaternion()
    # Bake scale/rotation so the outline thickness is in world units, not unit-sphere units.
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return finish(obj, material, outline)


def cylinder(name, center, radius, depth, material, axis="X", outline=True, vertices=32):
    rotation = {"X": (0.0, math.pi / 2, 0.0), "Y": (math.pi / 2, 0.0, 0.0), "Z": (0.0, 0.0, 0.0)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=center, rotation=rotation)
    obj = bpy.context.active_object
    obj.name = name
    return finish(obj, material, outline)


def cone(name, center, radius, depth, material, direction, outline=True):
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=radius, radius2=0.0, depth=depth, location=center)
    obj = bpy.context.active_object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(Vector(direction).normalized())
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return finish(obj, material, outline)


def cut_sphere(name, center, radius, scale, material, plane_point, plane_normal):
    """Sphere with everything on the positive side of the plane removed (local coords)."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=radius, location=(0, 0, 0))
    obj = bpy.context.active_object
    obj.name = name
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    bmesh.ops.bisect_plane(bm, geom=geom, plane_co=plane_point, plane_no=plane_normal, clear_outer=True)
    bm.to_mesh(obj.data)
    bm.free()
    obj.location = center
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, material, outline=True)


def surface_frame(normal):
    """Rotation whose local +X is `normal` and local +Z is as close to world up as possible."""
    x = normal.normalized()
    z = (Vector((0, 0, 1)) - x * x.z).normalized()
    y = z.cross(x)
    return Matrix((x, y, z)).transposed()


def head_point(yaw_degrees, pitch_degrees, extra=0.0):
    """Point on the (scaled) head surface, character-local frame (facing +X)."""
    yaw, pitch = math.radians(yaw_degrees), math.radians(pitch_degrees)
    direction = Vector((math.cos(pitch) * math.cos(yaw), math.cos(pitch) * math.sin(yaw), math.sin(pitch)))
    scaled = Vector((direction.x * HEAD_SCALE[0], direction.y * HEAD_SCALE[1], direction.z * HEAD_SCALE[2]))
    point = Vector((0, 0, HEAD_CENTER_Z)) + scaled * (HEAD_RADIUS + extra)
    return point, direction


def parent_all(objects, parent):
    for obj in objects:
        obj.parent = parent


# --- Character ---------------------------------------------------------------------------


def build_character(colors, pose):
    parts = []
    skin = toon_material("Skin", SKIN)
    shirt = toon_material("Shirt", colors["shirt"])
    pants = toon_material("Pants", colors["pants"])
    shoes = toon_material("Shoes", colors["shoes"])
    hair = toon_material("Hair", colors["hair"])

    # Feet and short legs.
    for side, y in (("Front", -0.075), ("Back", 0.075)):
        parts.append(ellipsoid(f"Shoe{side}", (0.035, y, 0.045), (0.095, 0.06, 0.05), shoes))
        parts.append(ellipsoid(f"Leg{side}", (0.0, y, 0.12), (0.05, 0.05, 0.075), pants))
    # Small torso.
    parts.append(ellipsoid("Torso", (0.0, 0.0, 0.31), (0.125, 0.115, 0.15), shirt))
    parts.append(ellipsoid("Belt", (0.0, 0.0, 0.205), (0.12, 0.11, 0.035), pants))

    # Arms: idle hangs at the sides; aim brings the back arm towards the weapon grip
    # (the front hand is drawn with the weapon sprite).
    if pose == "idle":
        for side, y in (("Front", -0.13), ("Back", 0.13)):
            parts.append(ellipsoid(f"Arm{side}", (0.0, y, 0.3), (0.04, 0.04, 0.09), shirt))
            parts.append(ellipsoid(f"Hand{side}", (0.01, y, 0.2), (0.045, 0.045, 0.045), skin))
    else:
        arm = Matrix.Rotation(math.radians(-62), 3, "Y")
        parts.append(ellipsoid("ArmBack", (0.09, 0.1, 0.3), (0.04, 0.04, 0.1), shirt, rotation=arm))
        parts.append(ellipsoid("HandBack", (0.17, 0.08, 0.27), (0.045, 0.045, 0.045), skin))

    # Big head.
    parts.append(ellipsoid("Head", (0.0, 0.0, HEAD_CENTER_Z), tuple(HEAD_RADIUS * s for s in HEAD_SCALE), skin, segments=64, rings=32))
    for side, yaw in (("Front", -90.0), ("Back", 90.0)):
        point, _ = head_point(yaw, -8.0)
        parts.append(ellipsoid(f"Ear{side}", point, (0.04, 0.03, 0.055), skin))

    # Hair: back/top cap with the face cut away, bangs and a top tuft.
    center = (0.0, 0.0, HEAD_CENTER_Z + 0.01)
    radii = tuple(s * 1.0 for s in HEAD_SCALE)
    parts.append(cut_sphere("HairBack", center, HEAD_RADIUS + 0.025, radii, hair, (0.05, 0, 0), (1, 0, -0.35)))
    parts.append(cut_sphere("HairTop", center, HEAD_RADIUS + 0.028, radii, hair, (0, 0, 0.07), (0, 0, -1)))
    for index, yaw in enumerate((-38.0, -14.0, 10.0, 32.0)):
        tip, direction = head_point(yaw, 18.0, extra=0.03)
        root, _ = head_point(yaw, 42.0, extra=0.025)
        parts.append(cone(f"Bang{index}", (root + tip) / 2, 0.075, (tip - root).length * 1.6, hair, tip - root))
    tuft_root, _ = head_point(-20.0, 80.0, extra=0.02)
    parts.append(cone("Tuft", tuft_root + Vector((0.02, 0, 0.05)), 0.04, 0.14, hair, (0.5, 0, 1)))

    # Large graphic eyes (white, iris, pupil, highlight), blush and mouth.
    for side, yaw in (("Left", -48.0), ("Right", -8.0)):
        point, normal = head_point(yaw, -2.0, extra=-0.004)
        frame = surface_frame(normal)
        parts.append(ellipsoid(f"Eye{side}", point, (0.014, 0.05, 0.068), flat_material("EyeWhite", WHITE), rotation=frame))
        iris_point = point + normal * 0.006 + frame @ Vector((0, 0.004, -0.008))
        parts.append(ellipsoid(f"Iris{side}", iris_point, (0.012, 0.036, 0.05), flat_material("Iris", colors["iris"]), rotation=frame, outline=False))
        pupil_point = point + normal * 0.011 + frame @ Vector((0, 0.004, -0.012))
        parts.append(ellipsoid(f"Pupil{side}", pupil_point, (0.01, 0.019, 0.027), flat_material("Pupil", DARK), rotation=frame, outline=False))
        shine_point = point + normal * 0.016 + frame @ Vector((0, -0.012, 0.016))
        parts.append(ellipsoid(f"Shine{side}", shine_point, (0.006, 0.012, 0.012), flat_material("Shine", WHITE), rotation=frame, outline=False))
        blush_point, blush_normal = head_point(yaw - 6.0, -26.0, extra=-0.002)
        parts.append(ellipsoid(f"Blush{side}", blush_point, (0.006, 0.035, 0.016), flat_material("Blush", (1.0, 0.55, 0.6)), rotation=surface_frame(blush_normal), outline=False))
    mouth_point, mouth_normal = head_point(-28.0, -34.0, extra=-0.002)
    parts.append(ellipsoid("Mouth", mouth_point, (0.006, 0.026, 0.012), flat_material("Mouth", (0.55, 0.18, 0.2)), rotation=surface_frame(mouth_normal), outline=False))

    root = bpy.data.objects.new("CharacterRoot", None)
    bpy.context.collection.objects.link(root)
    parent_all(parts, root)
    root.rotation_euler = (0.0, 0.0, math.radians(BODY_YAW_DEGREES))
    return root


# --- Weapon and projectile ---------------------------------------------------------------


def build_weapon():
    parts = []
    tube = toon_material("Tube", WEAPON_COLORS["tube"])
    ring = toon_material("Ring", WEAPON_COLORS["ring"])
    dark = toon_material("Dark", WEAPON_COLORS["dark"])
    fin = toon_material("Fin", WEAPON_COLORS["fin"])
    parts.append(cylinder("Barrel", (0.15, 0, 0.0), 0.062, 0.52, tube))
    parts.append(cylinder("Muzzle", (BARREL_LENGTH - 0.03, 0, 0.0), 0.083, 0.07, ring))
    parts.append(cylinder("Stripe", (0.2, 0, 0.0), 0.066, 0.035, dark))
    parts.append(cylinder("RearCap", (-0.12, 0, 0.0), 0.075, 0.05, dark))
    parts.append(ellipsoid("Scope", (0.1, -0.0, 0.085), (0.07, 0.03, 0.03), ring))
    for z in (0.07, -0.07):
        parts.append(ellipsoid(f"Fin{z}", (-0.13, 0, z), (0.05, 0.012, 0.035), fin))
    parts.append(ellipsoid("Grip", (0.0, 0, -0.07), (0.025, 0.025, 0.05), dark))
    parts.append(ellipsoid("Hand", (0.0, -0.05, -0.02), (0.05, 0.045, 0.05), toon_material("Skin", SKIN)))
    root = bpy.data.objects.new("WeaponRoot", None)
    bpy.context.collection.objects.link(root)
    parent_all(parts, root)
    return root


def build_projectile():
    parts = []
    parts.append(ellipsoid("ShellBody", (0.0, 0, 0), (0.07, 0.045, 0.045), toon_material("ShellBody", PROJECTILE_COLORS["body"])))
    parts.append(cylinder("ShellBand", (0.0, 0, 0), 0.047, 0.025, toon_material("ShellBand", PROJECTILE_COLORS["band"])))
    for z in (0.035, -0.035):
        parts.append(ellipsoid(f"ShellFin{z}", (-0.065, 0, z), (0.03, 0.008, 0.022), toon_material("ShellFin", PROJECTILE_COLORS["fin"])))
    root = bpy.data.objects.new("ProjectileRoot", None)
    bpy.context.collection.objects.link(root)
    parent_all(parts, root)
    return root


# --- Rendering ---------------------------------------------------------------------------


def frame_size_px(frame):
    width = round((frame["right"] - frame["left"]) * PIXELS_PER_UNIT)
    height = round((frame["top"] - frame["bottom"]) * PIXELS_PER_UNIT)
    return width, height


def render(frame, path):
    scene = bpy.context.scene
    width, height = frame_size_px(frame)
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    camera_data = bpy.data.cameras.new("Camera")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = max(frame["right"] - frame["left"], frame["top"] - frame["bottom"])
    camera = bpy.data.objects.new("Camera", camera_data)
    scene.collection.objects.link(camera)
    camera.location = ((frame["left"] + frame["right"]) / 2, -10.0, (frame["bottom"] + frame["top"]) / 2)
    camera.rotation_euler = (math.pi / 2, 0.0, 0.0)
    scene.camera = camera
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(camera)


def to_pixels(frame, x, z):
    return [(x - frame["left"]) * PIXELS_PER_UNIT, (frame["top"] - z) * PIXELS_PER_UNIT]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = argv[argv.index("--out") + 1]
    os.makedirs(out, exist_ok=True)

    for variant, colors in VARIANTS.items():
        for pose in ("idle", "aim"):
            reset_scene()
            root = build_character(colors, pose)
            bpy.context.view_layer.update()
            render(BODY_FRAME, os.path.join(out, f"player_{variant}_{pose}.png"))

    reset_scene()
    build_weapon()
    render(WEAPON_FRAME, os.path.join(out, "weapon_launcher.png"))
    reset_scene()
    build_projectile()
    render(PROJECTILE_FRAME, os.path.join(out, "projectile_shell.png"))

    hair_top = HEAD_CENTER_Z + (HEAD_RADIUS + 0.028) * HEAD_SCALE[2] + 0.01 + 0.08
    meta = {
        "generator": "tools/blender/create_reference_character.py",
        "blender_version": bpy.app.version_string,
        "pixels_per_unit": PIXELS_PER_UNIT,
        "body": {
            "size_px": list(frame_size_px(BODY_FRAME)),
            "feet_anchor_px": to_pixels(BODY_FRAME, 0.0, 0.0),
            "head_center_u": [0.0, HEAD_CENTER_Z],
            "head_visual_radius_u": [HEAD_RADIUS * HEAD_SCALE[0], HEAD_RADIUS * HEAD_SCALE[2]],
            "approx_total_height_u": round(hair_top, 3),
            "weapon_pivot_u": list(WEAPON_PIVOT),
            "body_yaw_degrees": BODY_YAW_DEGREES,
        },
        "weapon": {
            "size_px": list(frame_size_px(WEAPON_FRAME)),
            "pivot_px": to_pixels(WEAPON_FRAME, 0.0, 0.0),
            "barrel_length_u": BARREL_LENGTH,
        },
        "projectile": {
            "size_px": list(frame_size_px(PROJECTILE_FRAME)),
            "center_px": to_pixels(PROJECTILE_FRAME, 0.0, 0.0),
        },
    }
    with open(os.path.join(out, "proxy_meta.json"), "w") as handle:
        json.dump(meta, handle, indent=2)
    print("REFERENCE CHARACTER DONE", out)


main()
