class_name CityBuilding
extends Control
## A clickable building of the City hub: Blender proxy sprite, hover lift and glow,
## and a name ribbon. Emits `activated`.

signal activated

var texture: Texture2D
var title: String = ""
var subtitle: String = ""
var _hover: bool = false
var _time: float = 0.0


static func create(p_texture: Texture2D, p_title: String, p_subtitle: String, center: Vector2, building_size: float) -> CityBuilding:
	var building := CityBuilding.new()
	building.texture = p_texture
	building.title = p_title
	building.subtitle = p_subtitle
	building.size = Vector2(building_size, building_size)
	building.position = center - building.size * 0.5
	building.tooltip_text = p_subtitle
	building.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return building


func _ready() -> void:
	mouse_entered.connect(func() -> void: _hover = true)
	mouse_exited.connect(func() -> void: _hover = false)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		activated.emit()
		accept_event()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var lift: float = -6.0 - sin(_time * 5.0) * 3.0 if _hover else 0.0
	draw_set_transform(Vector2(size.x * 0.5, size.y * 0.86), 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, size.x * 0.36, Color(0.1, 0.1, 0.2, 0.25))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if _hover:
		draw_circle(size * 0.5 + Vector2(0, lift), size.x * 0.45, Color(1.0, 0.95, 0.6, 0.18))
	draw_texture_rect(texture, Rect2(Vector2(0, lift), size), false, Color(1.15, 1.15, 1.15) if _hover else Color.WHITE)
	var font: Font = UiKit.bold_font()
	var font_size: int = 22
	var text_width: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var ribbon := Rect2(Vector2((size.x - text_width) * 0.5 - 16, size.y * 0.86), Vector2(text_width + 32, 36))
	draw_style_box(UiKit.box(UiKit.ORANGE if _hover else UiKit.NAVY, UiKit.GOLD, 12, 3, 4), ribbon)
	draw_string_outline(font, ribbon.position + Vector2(16, 26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, UiKit.OUTLINE)
	draw_string(font, ribbon.position + Vector2(16, 26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiKit.TEXT)
