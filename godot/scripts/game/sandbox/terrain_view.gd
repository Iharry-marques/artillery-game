class_name TerrainView
extends Sprite2D
## Draws a TerrainMask as a texture: one texel per terrain cell, transparent where
## empty. Craters only re-upload the texture; the mask stays the source of truth.

const SURFACE_COLOR: Color = Color(0.47, 0.58, 0.38)
const EARTH_COLOR: Color = Color(0.42, 0.34, 0.26)
const DEEP_COLOR: Color = Color(0.24, 0.2, 0.16)
const SCORCH_COLOR: Color = Color(0.16, 0.13, 0.11)
## Depth (u) of the lighter surface band and of the full earth-to-deep gradient.
const SURFACE_DEPTH: float = 0.15
const GRADIENT_DEPTH: float = 6.0
## Width (u) of the darkened ring left around a crater.
const SCORCH_WIDTH: float = 0.12

var _terrain: TerrainMask
var _rgba: PackedByteArray
var _image: Image
var _texture: ImageTexture


func build(terrain: TerrainMask) -> void:
	_terrain = terrain
	_rgba = PackedByteArray()
	_rgba.resize(terrain.columns * terrain.rows * 4)
	for col in terrain.columns:
		var depth_cells: int = 0
		for row in terrain.rows:
			if terrain.is_solid_cell(col, row):
				_write(col, row, _base_color(depth_cells * terrain.cell_size))
				depth_cells += 1
			else:
				_write(col, row, Color(0, 0, 0, 0))
				depth_cells = 0
	_image = Image.create_from_data(terrain.columns, terrain.rows, false, Image.FORMAT_RGBA8, _rgba)
	_texture = ImageTexture.create_from_image(_image)
	texture = _texture
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	scale = Vector2.ONE * terrain.cell_size * WorldCanvas.PIXELS_PER_UNIT


## Clears the carved cells of `region` and darkens a thin ring around the crater.
func apply_crater(region: Rect2i, cx: float, cy: float, radius: float) -> void:
	var cell: float = _terrain.cell_size
	var ring: Rect2i = region.grow(ceili(SCORCH_WIDTH / cell)).intersection(Rect2i(0, 0, _terrain.columns, _terrain.rows))
	for row in range(ring.position.y, ring.end.y):
		for col in range(ring.position.x, ring.end.x):
			if not _terrain.is_solid_cell(col, row):
				_write(col, row, Color(0, 0, 0, 0))
				continue
			var d: float = Vector2((col + 0.5) * cell - cx, (row + 0.5) * cell - cy).length()
			if d <= radius + SCORCH_WIDTH:
				_write(col, row, SCORCH_COLOR)
	_image.set_data(_terrain.columns, _terrain.rows, false, Image.FORMAT_RGBA8, _rgba)
	_texture.update(_image)


func _base_color(depth: float) -> Color:
	if depth < SURFACE_DEPTH:
		return SURFACE_COLOR
	return EARTH_COLOR.lerp(DEEP_COLOR, clampf(depth / GRADIENT_DEPTH, 0.0, 1.0))


func _write(col: int, row: int, color: Color) -> void:
	var i: int = (row * _terrain.columns + col) * 4
	_rgba[i] = color.r8
	_rgba[i + 1] = color.g8
	_rgba[i + 2] = color.b8
	_rgba[i + 3] = color.a8
