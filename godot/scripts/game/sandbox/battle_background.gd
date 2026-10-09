class_name BattleBackground
extends Node
## Original procedural backdrop (presentation only), drawn in screen space behind
## the world: a sky gradient with a sun, then clouds, far mountains and mid-distance
## hills with trees. Each layer moves by `parallax` times the camera motion (manual
## parallax, so the layout is fully deterministic). Colours are desaturated so the
## playable terrain stays the most saturated element.

const SKY_TOP: Color = Color(0.36, 0.62, 0.96)
const SKY_HORIZON: Color = Color(0.86, 0.94, 1.0)
const SUN_COLOR: Color = Color(1.0, 0.97, 0.82)
## Width (screen px at 720p) of one horizontally repeated tile.
const TILE_WIDTH_PX: float = 1600.0
## Reference screen height the layer sizes are authored for.
const AUTHORED_HEIGHT_PX: float = 720.0

var camera: BattleCamera
## Camera centre (canvas px) at which every layer sits at its authored height.
var reference_camera_px: Vector2 = Vector2.ZERO
var _layers: Array[_LayerArt] = []


func _ready() -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -100
	add_child(sky_layer)
	var sky := TextureRect.new()
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var gradient := Gradient.new()
	gradient.set_color(0, SKY_TOP)
	gradient.set_color(1, SKY_HORIZON)
	var sky_texture := GradientTexture2D.new()
	sky_texture.gradient = gradient
	sky_texture.fill_from = Vector2(0.5, 0.0)
	sky_texture.fill_to = Vector2(0.5, 1.0)
	sky.texture = sky_texture
	sky_layer.add_child(sky)

	var parallax_layer := CanvasLayer.new()
	parallax_layer.layer = -90
	add_child(parallax_layer)
	# (kind, parallax factor, base height as a fraction of the screen from the top).
	for spec: Vector3 in [Vector3(0, 0.08, 0.32), Vector3(1, 0.18, 0.66), Vector3(2, 0.38, 0.76)]:
		var art := _LayerArt.new()
		art.kind = int(spec.x)
		art.parallax = spec.y
		art.base_fraction = spec.z
		parallax_layer.add_child(art)
		_layers.append(art)


func _process(delta: float) -> void:
	if camera == null:
		return
	for art in _layers:
		art.camera_shift_px = (camera.position - reference_camera_px) * camera.zoom.x
		art.time += delta
		art.queue_redraw()


class _LayerArt:
	extends Node2D
	var kind: int = 0
	var parallax: float = 0.0
	var base_fraction: float = 0.0
	var camera_shift_px: Vector2 = Vector2.ZERO
	var time: float = 0.0
	const CLOUD_DRIFT_PX: float = 6.0

	func _draw() -> void:
		var view: Vector2 = get_viewport_rect().size
		var unit: float = view.y / AUTHORED_HEIGHT_PX
		var tile: float = TILE_WIDTH_PX * unit
		var drift: float = time * CLOUD_DRIFT_PX if kind == 0 else 0.0
		var offset_x: float = fposmod(-camera_shift_px.x * parallax + drift, tile)
		var base_y: float = view.y * base_fraction - camera_shift_px.y * parallax
		if kind == 0:
			_draw_sun(view, unit)
		var k: int = -1
		while offset_x + k * tile < view.x:
			draw_set_transform(Vector2(offset_x + k * tile, base_y), 0.0, Vector2.ONE * unit)
			var rng := RandomNumberGenerator.new()
			rng.seed = 4242 + kind
			match kind:
				0:
					_draw_clouds(rng)
				1:
					_draw_ridge(rng, Color(0.66, 0.72, 0.9), 250.0, 90.0, 7, true)
					_draw_ridge(rng, Color(0.58, 0.66, 0.86), 170.0, 60.0, 10, false)
				2:
					_draw_ridge(rng, Color(0.56, 0.75, 0.68), 95.0, 40.0, 6, false)
					_draw_trees(rng)
			k += 1
		draw_set_transform_matrix(Transform2D.IDENTITY)

	func _draw_sun(view: Vector2, unit: float) -> void:
		var center := Vector2(view.x * 0.16, view.y * 0.14 - camera_shift_px.y * 0.03)
		for i in 5:
			draw_circle(center, (40.0 + i * 14.0) * unit, Color(1.0, 0.97, 0.8, 0.08))
		draw_circle(center, 34.0 * unit, SUN_COLOR)

	func _draw_clouds(rng: RandomNumberGenerator) -> void:
		for i in 6:
			var center := Vector2(rng.randf_range(0.0, TILE_WIDTH_PX), -rng.randf_range(0.0, 170.0))
			var width: float = rng.randf_range(110.0, 200.0)
			for j in 5:
				var offset := Vector2((j - 2) * width * 0.2, -(2.0 - absf(j - 2.0)) * 12.0)
				var radius: float = width * (0.2 if j % 2 == 0 else 0.26)
				draw_circle(center + offset + Vector2(0, 7), radius, Color(0.72, 0.8, 0.94, 0.55))
				draw_circle(center + offset, radius, Color(1.0, 1.0, 1.0, 0.95))

	func _draw_ridge(rng: RandomNumberGenerator, color: Color, height: float, variation: float, peaks: int, snow: bool) -> void:
		var step: float = TILE_WIDTH_PX / peaks
		var first: float = -height * 0.5
		var points := PackedVector2Array([Vector2(0.0, 2000.0), Vector2(0.0, first)])
		var tops: Array[Vector2] = []
		for i in peaks:
			var peak := Vector2((i + 0.5) * step, -height + rng.randf_range(-variation, variation) * 0.6)
			points.append(peak)
			tops.append(peak)
			var valley_y: float = first if i == peaks - 1 else -height * 0.45 + rng.randf_range(-variation, variation) * 0.3
			points.append(Vector2((i + 1) * step, valley_y))
		points.append(Vector2(TILE_WIDTH_PX, 2000.0))
		draw_colored_polygon(points, color)
		if snow:
			for peak in tops:
				var half: float = 34.0
				draw_colored_polygon(PackedVector2Array([peak, peak + Vector2(half, half * 0.9), peak + Vector2(0, half * 0.6), peak + Vector2(-half, half * 0.9)]), Color(0.95, 0.97, 1.0, 0.92))

	func _draw_trees(rng: RandomNumberGenerator) -> void:
		for i in 14:
			var x: float = rng.randf_range(0.0, TILE_WIDTH_PX)
			var ground: float = -rng.randf_range(20.0, 60.0)
			var size: float = rng.randf_range(22.0, 36.0)
			draw_rect(Rect2(x - 3.0, ground - size * 0.5, 6.0, size * 0.6), Color(0.45, 0.5, 0.5))
			draw_circle(Vector2(x, ground - size * 0.9), size * 0.5, Color(0.42, 0.64, 0.56))
			draw_circle(Vector2(x - size * 0.15, ground - size), size * 0.28, Color(0.52, 0.74, 0.64))
