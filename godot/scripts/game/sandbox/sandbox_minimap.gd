class_name SandboxMinimap
extends Control
## Geometrically faithful minimap: terrain silhouette sampled from the mask,
## player markers, the projectile and the camera rectangle. The rectangle is
## exactly the 10 u battle view, with tick marks splitting it into 10 units: the
## players' distance ruler.

## Width on screen; the height follows the map aspect so both axes share one scale.
const WIDTH_PX: float = 320.0
const BACKGROUND: Color = Color(0.05, 0.06, 0.08, 0.75)
const TERRAIN_COLOR: Color = Color(0.55, 0.5, 0.42)
const CAMERA_COLOR: Color = Color(1.0, 1.0, 1.0, 0.9)
const PROJECTILE_COLOR: Color = Color(1.0, 0.95, 0.7)
const MARKER_RADIUS_PX: float = 4.0
const TICK_PX: float = 5.0

var combat: CombatMatch
var camera: BattleCamera
var projectile: ProjectileView
var player_colors: Array[Color] = []
var _terrain_version: int = -1
var _terrain_texture: ImageTexture


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func size_px() -> Vector2:
	return Vector2(WIDTH_PX, WIDTH_PX * combat.rules.map_height / combat.rules.map_width)


func invalidate() -> void:
	_terrain_version = -1


func _process(_delta: float) -> void:
	if combat != null and combat.terrain.version != _terrain_version:
		_rebuild_terrain_texture()
	queue_redraw()


func _draw() -> void:
	if combat == null:
		return
	custom_minimum_size = size_px()
	draw_rect(Rect2(Vector2.ZERO, size_px()), BACKGROUND)
	if _terrain_texture != null:
		draw_texture_rect(_terrain_texture, Rect2(Vector2.ZERO, size_px()), false)
	for c in combat.combatants:
		var color: Color = player_colors[c.index] if c.alive else Color(0.5, 0.5, 0.5)
		var at: Vector2 = _to_minimap(Vector2(c.feet_x, c.head_center_y(combat.rules)))
		draw_circle(at, MARKER_RADIUS_PX, color)
		if c.index == combat.active_index:
			draw_arc(at, MARKER_RADIUS_PX + 3.0, 0.0, TAU, 20, Color.WHITE, 1.5)
	if combat.phase == CombatMatch.Phase.FLIGHT:
		draw_circle(_to_minimap(projectile.current_position_units()), 2.5, PROJECTILE_COLOR)
	_draw_camera_ruler()
	draw_rect(Rect2(Vector2.ZERO, size_px()), Color(1, 1, 1, 0.3), false, 1.0)


func _draw_camera_ruler() -> void:
	var view: Rect2 = camera.visible_rect_units()
	var top_left: Vector2 = _to_minimap(view.position)
	var bottom_right: Vector2 = _to_minimap(view.end)
	var rect := Rect2(top_left, bottom_right - top_left)
	draw_rect(rect, CAMERA_COLOR, false, 1.5)
	var divisions: int = roundi(view.size.x)
	for i in range(1, divisions):
		var x: float = rect.position.x + rect.size.x * i / divisions
		var length: float = TICK_PX * (1.6 if i % 5 == 0 else 1.0)
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + length), CAMERA_COLOR, 1.0)
		draw_line(Vector2(x, rect.end.y), Vector2(x, rect.end.y - length), CAMERA_COLOR, 1.0)


## World units -> minimap pixels; points above or below the map stick to the edge.
func _to_minimap(point_units: Vector2) -> Vector2:
	var rules: CombatRules = combat.rules
	var px: Vector2 = size_px()
	return Vector2(point_units.x / rules.map_width * px.x, clampf(point_units.y / rules.map_height, 0.0, 1.0) * px.y)


func _rebuild_terrain_texture() -> void:
	var w: int = int(size_px().x)
	var h: int = int(size_px().y)
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var terrain: TerrainMask = combat.terrain
	for py in h:
		var y: float = (py + 0.5) / h * terrain.height_units()
		for px in w:
			if terrain.is_solid((px + 0.5) / w * terrain.width_units(), y):
				image.set_pixel(px, py, TERRAIN_COLOR)
	_terrain_texture = ImageTexture.create_from_image(image)
	_terrain_version = terrain.version
