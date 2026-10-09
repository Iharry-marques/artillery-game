class_name SandboxMinimap
extends Control
## Gameplay instrument: terrain silhouette sampled from the mask, player markers,
## the projectile and the camera rectangle. The rectangle is exactly the 10 u
## battle view, split into 10 ticks: the distance ruler players read.

const WIDTH_PX: float = 300.0
const FRAME_PX: float = 4.0
const FRAME_COLOR: Color = Color(0.1, 0.12, 0.2, 0.92)
const FRAME_LIGHT: Color = Color(0.55, 0.7, 0.95, 0.9)
const SKY_TOP: Color = Color(0.25, 0.42, 0.7)
const SKY_BOTTOM: Color = Color(0.55, 0.72, 0.9)
const SOIL_COLOR: Color = Color(0.72, 0.52, 0.34)
const GRASS_COLOR: Color = Color(0.5, 0.85, 0.32)
const CAMERA_COLOR: Color = Color(1.0, 1.0, 1.0, 0.95)
const PROJECTILE_COLOR: Color = Color(1.0, 0.9, 0.4)
const MARKER_RADIUS_PX: float = 5.0
const TICK_PX: float = 4.0

var combat: CombatMatch
var camera: BattleCamera
var projectile: ProjectileView
var player_colors: Array[Color] = []
var _terrain_version: int = -1
var _terrain_texture: ImageTexture


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func projection() -> MinimapProjection:
	return MinimapProjection.new(Vector2(combat.rules.map_width, combat.rules.map_height), WIDTH_PX)


func invalidate() -> void:
	_terrain_version = -1


func _process(_delta: float) -> void:
	if combat != null and combat.terrain.version != _terrain_version:
		_rebuild_terrain_texture()
	queue_redraw()


func _draw() -> void:
	if combat == null:
		return
	var p: MinimapProjection = projection()
	var area := Rect2(Vector2.ZERO, p.size_px())
	custom_minimum_size = area.size + Vector2.ONE * FRAME_PX * 2.0
	draw_set_transform(Vector2.ONE * FRAME_PX, 0.0, Vector2.ONE)
	draw_rect(area.grow(FRAME_PX), FRAME_COLOR)
	if _terrain_texture != null:
		draw_texture_rect(_terrain_texture, area, false)
	if combat.phase == CombatMatch.Phase.FLIGHT:
		draw_circle(p.to_minimap(projectile.current_position_units()), 3.0, PROJECTILE_COLOR)
	for c in combat.combatants:
		var at: Vector2 = p.to_minimap(Vector2(c.feet_x, c.head_center_y(combat.rules)))
		var color: Color = player_colors[c.index] if c.alive else Color(0.5, 0.5, 0.5)
		draw_circle(at, MARKER_RADIUS_PX + 1.5, Color(0.05, 0.05, 0.1))
		draw_circle(at, MARKER_RADIUS_PX, color)
		if c.index == combat.active_index and combat.phase != CombatMatch.Phase.GAME_OVER:
			draw_arc(at, MARKER_RADIUS_PX + 3.5, 0.0, TAU, 24, Color.WHITE, 1.5)
	_draw_camera_ruler(p)
	draw_rect(area.grow(1.0), FRAME_LIGHT, false, 1.5)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_camera_ruler(p: MinimapProjection) -> void:
	var view: Rect2 = camera.visible_rect_units()
	var rect: Rect2 = p.rect_to_minimap(view)
	draw_rect(rect, Color(1, 1, 1, 0.1))
	draw_rect(rect, CAMERA_COLOR, false, 1.5)
	var divisions: int = roundi(view.size.x)
	for i in range(1, divisions):
		var x: float = rect.position.x + rect.size.x * i / divisions
		var length: float = TICK_PX * (1.8 if i % 5 == 0 else 1.0)
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + length), CAMERA_COLOR, 1.0)
		draw_line(Vector2(x, rect.end.y), Vector2(x, rect.end.y - length), CAMERA_COLOR, 1.0)


func _rebuild_terrain_texture() -> void:
	var size: Vector2 = projection().size_px()
	var w: int = int(size.x)
	var h: int = int(size.y)
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var terrain: TerrainMask = combat.terrain
	for px in w:
		var x: float = (px + 0.5) / w * terrain.width_units()
		var previous_solid: bool = false
		for py in h:
			var solid: bool = terrain.is_solid(x, (py + 0.5) / h * terrain.height_units())
			if solid:
				image.set_pixel(px, py, GRASS_COLOR if not previous_solid else SOIL_COLOR)
			else:
				image.set_pixel(px, py, SKY_TOP.lerp(SKY_BOTTOM, float(py) / h))
			previous_solid = solid
	_terrain_texture = ImageTexture.create_from_image(image)
	_terrain_version = terrain.version
