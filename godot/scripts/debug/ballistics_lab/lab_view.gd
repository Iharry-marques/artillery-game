class_name LabView
extends RefCounted
## Presentation-only helpers for the Ballistics Lab. Gameplay never reads this.
##
## The Lab draws world units (u) at PIXELS_PER_UNIT canvas pixels per unit; the
## camera zoom decides how many screen pixels that becomes.

const PIXELS_PER_UNIT: float = 100.0
const FONT_SIZE: int = 13
const TEXT_MARGIN_PX: float = 4.0


static func to_canvas(x_units: float, y_units: float) -> Vector2:
	return Vector2(x_units, y_units) * PIXELS_PER_UNIT


static func units_to_canvas(point_units: Vector2) -> Vector2:
	return point_units * PIXELS_PER_UNIT


## Screen pixels per canvas pixel for this item (the camera zoom).
static func screen_scale(item: CanvasItem) -> float:
	return item.get_canvas_transform().get_scale().x


## Visible area in canvas pixels.
static func visible_canvas_rect(item: CanvasItem) -> Rect2:
	return item.get_canvas_transform().affine_inverse() * item.get_viewport_rect()


## Draws text with a constant on-screen size at a canvas position (baseline-left).
## Text that is partially visible is shifted to lie fully inside the view; text
## that is completely off-view stays where it is.
static func draw_text(item: CanvasItem, canvas_position: Vector2, text: String, color: Color) -> void:
	var scale: float = screen_scale(item)
	var view: Rect2 = visible_canvas_rect(item)
	var size: Vector2 = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE) / scale
	if view.intersects(Rect2(canvas_position - Vector2(0.0, size.y), size)):
		var margin: float = TEXT_MARGIN_PX / scale
		canvas_position.x = clampf(canvas_position.x, view.position.x + margin, maxf(view.position.x + margin, view.end.x - size.x - margin))
		canvas_position.y = clampf(canvas_position.y, view.position.y + size.y + margin, view.end.y - margin)
	item.draw_set_transform(canvas_position, 0.0, Vector2.ONE / scale)
	item.draw_string(ThemeDB.fallback_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
	item.draw_set_transform_matrix(Transform2D.IDENTITY)
