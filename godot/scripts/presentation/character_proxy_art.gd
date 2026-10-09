class_name CharacterProxyArt
extends RefCounted
## Loads the ORIGINAL proxy sprites rendered by tools/blender/create_reference_character.py
## and their metadata (pixels per unit, anchors, head geometry). Presentation only.

const DIRECTORY: String = "res://assets/characters/reference_proxy"
const META_FILE: String = "proxy_meta.json"
const VARIANTS: Array[String] = ["blue", "red"]

var pixels_per_unit: float
var body_size_px: Vector2
var feet_anchor_px: Vector2
## Head art centre above the feet and its (horizontal, vertical) radii, in u.
var head_center_u: Vector2
var head_visual_radius_u: Vector2
var total_height_u: float
var weapon_pivot_u: Vector2
var weapon_pivot_px: Vector2
var weapon_barrel_length_u: float
var projectile_center_px: Vector2
var bodies: Dictionary = {}
var weapon: Texture2D
var projectile: Texture2D
## Art key -> texture (launcher, mortar, spark / shell, boulder, spark, pebble).
var weapons: Dictionary = {}
var projectiles: Dictionary = {}

static var _cached: CharacterProxyArt


## Loaded once per run (textures are shared by every screen).
static func shared() -> CharacterProxyArt:
	if _cached == null:
		_cached = load_default()
	return _cached


static func load_default() -> CharacterProxyArt:
	var text: String = FileAccess.get_file_as_string(DIRECTORY.path_join(META_FILE))
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("Cannot read %s" % DIRECTORY.path_join(META_FILE))
		return null
	var meta: Dictionary = parsed
	var body: Dictionary = meta["body"]
	var weapon_meta: Dictionary = meta["weapon"]
	var projectile_meta: Dictionary = meta["projectile"]
	var art := CharacterProxyArt.new()
	art.pixels_per_unit = meta["pixels_per_unit"] as float
	art.body_size_px = _vec(body["size_px"] as Array)
	art.feet_anchor_px = _vec(body["feet_anchor_px"] as Array)
	art.head_center_u = _vec(body["head_center_u"] as Array)
	art.head_visual_radius_u = _vec(body["head_visual_radius_u"] as Array)
	art.total_height_u = body["approx_total_height_u"] as float
	art.weapon_pivot_u = _vec(body["weapon_pivot_u"] as Array)
	art.weapon_pivot_px = _vec(weapon_meta["pivot_px"] as Array)
	art.weapon_barrel_length_u = weapon_meta["barrel_length_u"] as float
	art.projectile_center_px = _vec(projectile_meta["center_px"] as Array)
	for variant in VARIANTS:
		for pose: String in ["idle", "aim"]:
			art.bodies["%s_%s" % [variant, pose]] = load(DIRECTORY.path_join("player_%s_%s.png" % [variant, pose])) as Texture2D
	for key: String in ["launcher", "mortar", "spark"]:
		art.weapons[StringName(key)] = load(DIRECTORY.path_join("weapon_%s.png" % key)) as Texture2D
	for key: String in ["shell", "boulder", "spark", "pebble"]:
		art.projectiles[StringName(key)] = load(DIRECTORY.path_join("projectile_%s.png" % key)) as Texture2D
	art.weapon = art.weapons[&"launcher"]
	art.projectile = art.projectiles[&"shell"]
	return art


func weapon_texture(key: StringName) -> Texture2D:
	return weapons.get(key, weapon)


func projectile_texture(key: StringName) -> Texture2D:
	return projectiles.get(key, projectile)


## Scale from art pixels to canvas pixels.
func sprite_scale() -> float:
	return WorldCanvas.PIXELS_PER_UNIT / pixels_per_unit


func body_texture(variant_index: int, aiming: bool) -> Texture2D:
	return bodies["%s_%s" % [VARIANTS[variant_index % VARIANTS.size()], "aim" if aiming else "idle"]]


static func _vec(values: Array) -> Vector2:
	var x: float = values[0]
	var y: float = values[1]
	return Vector2(x, y)
