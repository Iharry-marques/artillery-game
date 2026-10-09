class_name TerrainView
extends Sprite2D
## Draws a TerrainMask through shaders/terrain.gdshader. The texture holds one texel
## per collision cell: r = solid now, g = solid originally, b = scorch. Craters only
## rewrite the affected texels; the mask stays the single source of truth.

const SHADER: Shader = preload("res://shaders/terrain.gdshader")
## Width (u) of the scorched band left around a crater, and its peak strength.
const SCORCH_WIDTH: float = 0.18
const SCORCH_MAX: int = 210

var _terrain: TerrainMask
var _data: PackedByteArray
var _image: Image
var _texture: ImageTexture


func build(terrain: TerrainMask) -> void:
	_terrain = terrain
	_data = PackedByteArray()
	_data.resize(terrain.columns * terrain.rows * 4)
	for row in terrain.rows:
		for col in terrain.columns:
			var i: int = (row * terrain.columns + col) * 4
			var solid: int = 255 if terrain.is_solid_cell(col, row) else 0
			_data[i] = solid
			_data[i + 1] = solid
			_data[i + 2] = 0
			_data[i + 3] = 255
	_image = Image.create_from_data(terrain.columns, terrain.rows, false, Image.FORMAT_RGBA8, _data)
	_texture = ImageTexture.create_from_image(_image)
	texture = _texture
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	scale = Vector2.ONE * terrain.cell_size * WorldCanvas.PIXELS_PER_UNIT
	var material_instance := ShaderMaterial.new()
	material_instance.shader = SHADER
	material_instance.set_shader_parameter("cell_size", terrain.cell_size)
	material = material_instance


## Clears the carved cells and scorches a band around the crater.
func apply_crater(region: Rect2i, cx: float, cy: float, radius: float) -> void:
	var cell: float = _terrain.cell_size
	var ring: Rect2i = region.grow(ceili(SCORCH_WIDTH / cell) + 1).intersection(Rect2i(0, 0, _terrain.columns, _terrain.rows))
	for row in range(ring.position.y, ring.end.y):
		for col in range(ring.position.x, ring.end.x):
			var i: int = (row * _terrain.columns + col) * 4
			var solid: bool = _terrain.is_solid_cell(col, row)
			_data[i] = 255 if solid else 0
			if solid:
				var d: float = Vector2((col + 0.5) * cell - cx, (row + 0.5) * cell - cy).length() - radius
				if d <= SCORCH_WIDTH:
					_data[i + 2] = maxi(_data[i + 2], roundi(SCORCH_MAX * (1.0 - clampf(d / SCORCH_WIDTH, 0.0, 1.0))))
	_image.set_data(_terrain.columns, _terrain.rows, false, Image.FORMAT_RGBA8, _data)
	_texture.update(_image)
