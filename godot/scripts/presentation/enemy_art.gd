class_name EnemyArt
extends RefCounted
## ORIGINAL proxy monster sprites (tools/blender/create_reference_enemies.py) and
## their metadata (feet anchor, head geometry for hitbox alignment).

const DIRECTORY: String = "res://assets/enemies"
const PIXELS_PER_UNIT: float = 256.0

static var _cached: EnemyArt

var textures: Dictionary = {}
## Visual key -> {"feet_anchor_px": Vector2, "head_center_u": Vector2, "head_radius_u": float, "size_px": Vector2}.
var meta: Dictionary = {}


static func shared() -> EnemyArt:
	if _cached == null:
		_cached = EnemyArt.new()
		_cached._load()
	return _cached


func _load() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY.path_join("enemy_meta.json")))
	if not parsed is Dictionary:
		push_error("Cannot read enemy_meta.json")
		return
	var data: Dictionary = parsed
	var enemies: Dictionary = DataReader.get_dict(data, "enemies")
	for key: String in enemies:
		var entry: Dictionary = enemies[key]
		var feet: Array = DataReader.get_array(entry, "feet_anchor_px")
		var head: Array = DataReader.get_array(entry, "head_center_u")
		var size: Array = DataReader.get_array(entry, "size_px")
		var fx: float = feet[0]
		var fy: float = feet[1]
		var hx: float = head[0]
		var hy: float = head[1]
		var sx: float = size[0]
		var sy: float = size[1]
		meta[StringName(key)] = {
			"feet_anchor_px": Vector2(fx, fy), "head_center_u": Vector2(hx, hy),
			"head_radius_u": DataReader.get_float(entry, "head_radius_u"), "size_px": Vector2(sx, sy),
		}
		textures[StringName(key)] = load(DIRECTORY.path_join("%s.png" % key)) as Texture2D


func has(visual: StringName) -> bool:
	return textures.has(visual)


func texture(visual: StringName) -> Texture2D:
	return textures.get(visual, null)


func feet_anchor_px(visual: StringName) -> Vector2:
	var entry: Dictionary = meta[visual]
	return entry["feet_anchor_px"]


func head_radius_u(visual: StringName) -> float:
	var entry: Dictionary = meta[visual]
	return entry["head_radius_u"]


func head_center_u(visual: StringName) -> Vector2:
	var entry: Dictionary = meta[visual]
	return entry["head_center_u"]


func sprite_scale() -> float:
	return WorldCanvas.PIXELS_PER_UNIT / PIXELS_PER_UNIT
