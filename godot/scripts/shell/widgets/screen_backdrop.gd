class_name ScreenBackdrop
extends Control
## Soft illustrated background for menu screens: sky gradient, floating light
## bubbles and rolling hills (procedural, original).

var top_color: Color = Color(0.3, 0.55, 0.95)
var bottom_color: Color = Color(0.75, 0.88, 1.0)
var hill_color: Color = Color(0.45, 0.78, 0.5)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var steps: int = 96
	for i in steps:
		var t: float = float(i) / steps
		draw_rect(Rect2(0, h * t, w, h / steps + 1.0), top_color.lerp(bottom_color, t))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 18:
		draw_circle(Vector2(rng.randf() * w, rng.randf() * h * 0.7), rng.randf_range(20, 80), Color(1, 1, 1, rng.randf_range(0.03, 0.08)))
	for layer in 2:
		var points := PackedVector2Array([Vector2(0, h)])
		var base: float = h * (0.78 + 0.08 * layer)
		for i in 33:
			var x: float = w * i / 32.0
			points.append(Vector2(x, base - sin(x * (0.004 + layer * 0.002) + layer) * 40.0 - 20.0))
		points.append(Vector2(w, h))
		draw_colored_polygon(points, hill_color.darkened(0.12 * layer) * Color(1, 1, 1, 0.9))
