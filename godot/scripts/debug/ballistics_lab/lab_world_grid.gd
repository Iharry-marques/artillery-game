class_name LabWorldGrid
extends Node2D
## World-space ruler: a vertical line every 1 u, stronger every 5 u, strongest
## every 10 u (one battle screen width), faint horizontal lines every 1 u, the
## y = 0 reference line and numeric labels along the view edges.

const MINOR_COLOR: Color = Color(1.0, 1.0, 1.0, 0.07)
const MAJOR_COLOR: Color = Color(1.0, 1.0, 1.0, 0.22)
const SCREEN_COLOR: Color = Color(0.35, 0.65, 1.0, 0.8)
const HORIZONTAL_COLOR: Color = Color(1.0, 1.0, 1.0, 0.04)
const BASELINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.85)
const LABEL_COLOR: Color = Color(0.82, 0.86, 0.92, 0.95)
const MINOR_WIDTH_PX: float = 1.0
const MAJOR_WIDTH_PX: float = 1.5
const SCREEN_WIDTH_PX: float = 2.5
const BASELINE_WIDTH_PX: float = 2.0
const MAJOR_EVERY_UNITS: int = 5
const SCREEN_EVERY_UNITS: int = 10
## Label steps tried in order; the first one with enough on-screen spacing wins.
const LABEL_STEPS: Array[int] = [1, 5, 10, 50, 100]
const MIN_LABEL_SPACING_PX: float = 44.0
## Bottom band reserved for x labels; y labels are not drawn inside it.
const LABEL_BAND_PX: float = 24.0
## Above this many 1 u lines (extreme zoom-out) minor lines are skipped.
const MAX_MINOR_LINES: int = 400


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var scale: float = LabView.screen_scale(self)
	var rect: Rect2 = LabView.visible_canvas_rect(self)
	var ppu: float = LabView.PIXELS_PER_UNIT
	var left: int = floori(rect.position.x / ppu)
	var right: int = ceili(rect.end.x / ppu)
	var top: int = floori(rect.position.y / ppu)
	var bottom: int = ceili(rect.end.y / ppu)
	var draw_minor: bool = (right - left) <= MAX_MINOR_LINES

	if draw_minor:
		for j in range(top, bottom + 1):
			if j != 0:
				draw_line(Vector2(rect.position.x, j * ppu), Vector2(rect.end.x, j * ppu), HORIZONTAL_COLOR, MINOR_WIDTH_PX / scale)

	for i in range(left, right + 1):
		var color: Color = MINOR_COLOR
		var width: float = MINOR_WIDTH_PX
		if i % SCREEN_EVERY_UNITS == 0:
			color = SCREEN_COLOR
			width = SCREEN_WIDTH_PX
		elif i % MAJOR_EVERY_UNITS == 0:
			color = MAJOR_COLOR
			width = MAJOR_WIDTH_PX
		elif not draw_minor:
			continue
		draw_line(Vector2(i * ppu, rect.position.y), Vector2(i * ppu, rect.end.y), color, width / scale)

	draw_line(Vector2(rect.position.x, 0.0), Vector2(rect.end.x, 0.0), BASELINE_COLOR, BASELINE_WIDTH_PX / scale)
	_draw_labels(rect, scale, left, right, top, bottom)


func _draw_labels(rect: Rect2, scale: float, left: int, right: int, top: int, bottom: int) -> void:
	var ppu: float = LabView.PIXELS_PER_UNIT
	var step: int = _label_step(scale)
	var margin: float = 4.0 / scale
	for i in range(left, right + 1):
		if i % step == 0:
			LabView.draw_text(self, Vector2(i * ppu + margin, rect.end.y - margin), "x %d" % i, LABEL_COLOR)
	var x_label_band: float = LABEL_BAND_PX / scale
	for j in range(top, bottom + 1):
		if j % step == 0 and j * ppu < rect.end.y - x_label_band:
			LabView.draw_text(self, Vector2(rect.position.x + margin, j * ppu - margin), "y %+d" % j if j != 0 else "y 0", LABEL_COLOR)


func _label_step(scale: float) -> int:
	var unit_on_screen_px: float = LabView.PIXELS_PER_UNIT * scale
	for step in LABEL_STEPS:
		if step * unit_on_screen_px >= MIN_LABEL_SPACING_PX:
			return step
	return LABEL_STEPS[LABEL_STEPS.size() - 1]
